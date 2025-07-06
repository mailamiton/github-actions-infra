# Use a slim base image for a smaller final image size
FROM python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Upgrade pip to ensure we have the latest version
RUN pip install --upgrade pip

# Copy all the necessary files for installation.
# NEVER copy the .env file into a Docker image.
COPY pyproject.toml .
COPY ./src ./src
COPY ./dbt ./dbt

# Install the project and all its dependencies from pyproject.toml.
# The '.' tells pip to install the project in the current directory.
RUN pip install --no-cache-dir .

# Set the entrypoint for the container to be our Python script.
# The command and its arguments will be passed to this script at runtime.
ENTRYPOINT ["python", "-m", "src.run_dbt"]