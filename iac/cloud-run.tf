resource "google_service_account" "cloud_run_elt_service_identity" {
  account_id = var.cloud_run_config.cloud_run_elt_name
  project    = var.project_id
}

resource "google_project_iam_member" "cloud_run_elt_service_sa_binding" {
  project = var.project_id
  for_each = toset([
    "roles/storage.objectAdmin",
    "roles/aiplatform.user",
    "roles/logging.logWriter",
    "roles/bigquery.dataViewer",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/cloudsql.client"
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.cloud_run_elt_service_identity.email}"
}

data "google_secret_manager_secret_version" "env_secret" {
  secret  = var.secret_manager.env_secret_name
  version = var.secret_manager.env_secret_version
  project = var.project_id
}

resource "google_cloud_run_v2_job" "elt_job" {
  name                = var.cloud_run_config.cloud_run_elt_name
  location            = var.default_location
  deletion_protection = false
  project             = var.project_id

  template {
    template {
      # --- Task-level settings apply to all containers ---
      vpc_access {
        connector = google_vpc_access_connector.cloud_run_connector.id
        egress    = "ALL_TRAFFIC"
      }
      service_account = google_service_account.cloud_run_elt_service_identity.email
      # Sets the maximum execution time for the job's task.
      # Format: string in seconds ending with 's'. Default: "600s".
      timeout = "21600s" # Set to 6 hours
      # --- Define the containers for the job ---
      containers {
        # --- Your Main ELT Job Container ---
        name  = "elt-job-container"
        image = var.cloud_run_config.elt_container_image_url

        dynamic "env" {
          for_each = split("\n", data.google_secret_manager_secret_version.env_secret.secret_data)
          iterator = line
          content {
            name = trimspace(split("=", line.value)[0])
            value = trimspace(replace(element(split("=", line.value), 1), "\r", ""))
          }
        }
        resources {
          limits = {
            "cpu"    = var.cloud_run_config.cloud_run_elt_cpu_num  
            "memory" = var.cloud_run_config.cloud_run_elt_memory_size 
          }
        }
      }

      containers {
        # --- Cloud SQL Auth Proxy Sidecar Container ---
        name  = "cloud-sql-proxy"
        image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:latest"
        # Command line arguments for the proxy
        args = [
          # Instance Connection Name (MUST be project:region:instance)
          "${var.project_id}:${var.default_location}:${var.cloud_sql_config.sql_instance_instance_name}",

          # Main proxy port config - make sure job connects to this port on localhost
          "--address=0.0.0.0",
          "--port=${var.cloud_sql_config.cloud_sql_instance_port}", # e.g., 5432

          # Connection options
          "--private-ip",     # Use Private IP as VPC connector is configured
          "--auto-iam-authn", # Use service account credentials via IAM

          # Health Check Config (Optional for Jobs but good practice)
          # Even without probes, these allow manual checks if needed
          "--health-check",
          "--http-port=9090",
          "--http-address=0.0.0.0",

          # Logging
          "--structured-logs"
        ]

        # Allocate resources for the proxy
        resources {
          limits = {
            # Ensure these variables are defined and provide adequate resources
            "cpu"    = var.cloud_run_config.cloud_run_sql_proxy_cpu_num
            "memory" = var.cloud_run_config.cloud_run_sql_proxy_memory_size
          }
        }
      }
    }
  }
}