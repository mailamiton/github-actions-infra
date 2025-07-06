resource "google_service_account" "scheduler_invoker_sa" {
  account_id  = var.cloud_run_config.cloud_run_elt_scheduler_name
  description = "Service Account for ELT Job Scheduler"
  project     = var.project_id
}

resource "google_cloud_run_v2_job_iam_binding" "job-binding" {
  for_each = toset(["run.invoker", "run.developer"]) // run.developer grants run.jobs.runWithOverrides
  name     = google_cloud_run_v2_job.elt_job.name
  location = var.default_location
  project  = var.project_id
  role     = "roles/${each.value}"
  members = [
    "serviceAccount:${google_service_account.scheduler_invoker_sa.email}"
  ]
}




# Example Service Account for the Scheduler Job (needs creation and permissions)
# resource "google_service_account" "scheduler_invoker_sa" {
#   account_id   = var.cloud_run_config.cloud_run_elt_scheduler_name #"elt-job-scheduler-sa" # Example
#   display_name = "Service Account for ELT Job Scheduler"
#   project      = var.project_id
# }

# Grant the Scheduler SA permission to run the Cloud Run Job
# resource "google_cloud_run_v2_job_iam_member" "scheduler_can_run_job" {
#   project  = google_cloud_run_v2_job.elt_job.project
#   location = google_cloud_run_v2_job.elt_job.location
#   name     = google_cloud_run_v2_job.elt_job.name
#   role     = "roles/run.invoker" # Role needed to execute the job
#   member   = "serviceAccount:${google_service_account.scheduler_invoker_sa.email}"
# }

# # Grant the Scheduler SA permission to impersonate the Cloud Run Job's runtime SA (if needed by OIDC)
# resource "google_service_account_iam_member" "scheduler_can_impersonate_run_sa" {
#   service_account_id = google_service_account.cloud_run_elt_service_identity.name # The SA the Cloud Run job runs as
#   role               = "roles/iam.serviceAccountUser"
#   member             = "serviceAccount:${google_service_account.scheduler_invoker_sa.email}"
# }

# --- Cloud Scheduler Job 1: target "cs_tac" ---
resource "google_cloud_scheduler_job" "cloud_run_job_trigger_cs_tac" {
  name        = "${var.cloud_run_config.cloud_run_elt_scheduler_name}-cs_tac"
  description = "Scheduled job to trigger Cloud Run Job for cs_tac target"
  schedule    = "0 2 * * *" # Example: Every day at 2:00 AM (UTC)
  time_zone   = "America/New_York"
  region      = var.default_location
  project     = var.project_id

  http_target {
    http_method = "POST"
    uri         = "https://${var.default_location}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.cloud_run_config.cloud_run_elt_name}:run"
    headers = {
      "Content-Type" = "application/json"
    }
    body = base64encode(jsonencode({
      overrides = {
        containerOverrides = [
          {
            name      = "elt-job-container",
            args      = ["--target", "cs_tac"],
            clearArgs = false
          }
        ]
      }
    }))
    oauth_token {
      service_account_email = google_service_account.scheduler_invoker_sa.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  depends_on = [google_cloud_run_v2_job.elt_job, google_cloud_run_v2_job_iam_binding.job-binding]
}

# --- Cloud Scheduler Job 2: target "cs_tac_activity" ---
resource "google_cloud_scheduler_job" "cloud_run_job_trigger_cs_tac_activity" {
  name        = "${var.cloud_run_config.cloud_run_elt_scheduler_name}-cs_tac_activity"
  description = "Scheduled job to trigger Cloud Run Job for cs_tac target"
  schedule    = "0 2 * * *" # Example: Every day at 2:00 AM (UTC)
  time_zone   = "America/New_York"
  region      = var.default_location
  project     = var.project_id

  http_target {
    http_method = "POST"
    uri         = "https://${var.default_location}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.cloud_run_config.cloud_run_elt_name}:run"
    headers = {
      "Content-Type" = "application/json"
    }
    body = base64encode(jsonencode({
      overrides = {
        containerOverrides = [
          {
            name      = "elt-job-container",
            args      = ["--target", "cs_tac_activity"],
            clearArgs = false
          }
        ]
      }
    }))
    oauth_token {
      service_account_email = google_service_account.scheduler_invoker_sa.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  depends_on = [google_cloud_run_v2_job.elt_job, google_cloud_run_v2_job_iam_binding.job-binding]
}
