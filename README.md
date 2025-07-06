Folder Structure Breakdown 

Container 
    - Dockerfile: example docker file that will accept command line arguments

dbt 
    - Simple dbt code examples (the project that gets created when you execute 'dbt init')

iac 
    - Examples of the cloud run job and cloud run scheduler (likely more set up to be done here)

src
    - Project application code, in this case, 2 python scripts. One that does not accept any arguments and one that does (target, full-refresh)

other
    - .env: where all environment variable are established, can be used by dbt code and app code
    - pyproject.toml: includes necessary configurations to run the 'run-dbt' python script (expected to be updated)
    - tasks.py: includes the python task to execute the 'run-dbt' python script

---

### Project Setup (Windows with Poetry)

This guide details how to set up the project on a Windows machine using [Poetry](https://python-poetry.org/) for dependency and environment management. This is the recommended approach.

#### Prerequisites

1.  **Install Python:** Based on `pyproject.toml`, this project requires Python 3.12. You can download it from the official Python website. During installation, it's recommended to check the box that says "Add python.exe to PATH".
2.  **Windows Terminal:** It is highly recommended to use the Windows Terminal for a better command-line experience. The following commands should be run in PowerShell.

#### Step 1: Install Poetry

Poetry is a tool for dependency management and packaging in Python. It will manage your project's virtual environment automatically. Open PowerShell and run the following command:

```powershell
(Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | py -
```

After installation is complete, you must close and reopen your terminal for the `poetry` command to be available in your PATH.

#### Step 2: Create Virtual Environment and Install Dependencies

With Poetry, creating the virtual environment and installing dependencies are done with a single, powerful command.

Navigate to the root directory of this project in your terminal and run:

```bash
poetry install
```

This single command will read the `pyproject.toml` file, automatically create a dedicated virtual environment for this project, and install all the required dependencies into it.


#### DBT Command 
1. To run this locally 

Your dbt project is located in the `dbt/` subdirectory. Before running any `dbt` commands, you must first navigate into that directory from the project root.

```powershell
# Navigate into the dbt project directory
cd dbt
```

Once inside the `dbt` directory, you can execute any dbt command. For example:

```bash
# Test your profile connection
dbt debug

# Run your dbt models
dbt run
```

### Running with Docker

This project includes a `Dockerfile` to build a containerized environment for running dbt. This is useful for ensuring consistency across different environments and for CI/CD pipelines.

#### Prerequisites

- Docker Desktop installed and running.

#### Building the Image

From the root directory of the project, run the following command to build the Docker image. We'll tag it as `tru-dbt` for easy reference.

```bash
docker build -t tru-dbt -f container/Dockerfile .
```

#### Running dbt Commands

Once the image is built, you can run any dbt command by passing it to `docker run`. The `ENTRYPOINT` is set to `dbt`, so you just need to provide the dbt command and its arguments.

- **Run dbt models (default command):**
  ```bash
  docker run --rm tru-dbt
  ```
  *This is equivalent to `docker run --rm tru-dbt run`.*

- **Build all models and run tests:**
  ```bash
  docker run --rm tru-dbt build
  ```

- **Run only tests:**
  ```bash
  docker run --rm tru-dbt test
  ```

- **Debug your dbt connection:**
  ```bash
  docker run --rm tru-dbt debug
  ```

- **Get an interactive shell inside the container:**
  This is useful for debugging or running commands manually inside the container's environment.
  ```bash
  docker run --rm -it tru-dbt bash
  ```

#### login  
 ```
 gcloud auth application-default login
 gcloud auth login
 ```
 