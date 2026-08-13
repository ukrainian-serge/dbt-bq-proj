# dbt Fundamentals Project

This project builds a Jaffle Shop-style analytics stack with dbt, BigQuery, and a lightweight local developer workflow. The model layer covers staging, intermediate logic, and marts, while the surrounding setup supports raw-data generation, service-account authentication, and dbt Cloud-triggered production runs.

## Project overview

The repository includes:
- dbt models for staging, intermediate, and analytics marts
- Python utilities for raw-data generation and BigQuery ingestion
- service-account-based authentication for dbt and Python tooling
- local environment management through direnv
- a dbt Cloud-compatible workflow for production job triggers

## Stack and cloud architecture

This stack centers on dbt Cloud for orchestration, with BigQuery as the warehouse and Google Cloud Platform as the underlying infrastructure. The project follows a modern ELT pattern:
- raw files land in object storage or a landing area
- raw datasets load into BigQuery
- dbt transforms and models the data into curated reporting tables
- dbt jobs in dbt Cloud trigger and orchestrate the production workflow

This setup makes the project a good example of how local development, cloud data engineering, and deployment automation fit together in a real analytics environment.

## GCP and BigQuery setup

The environment follows a standard Google Cloud setup:
- create or select a GCP project
- enable the required APIs, especially BigQuery
- create separate datasets for raw ingestion and transformed analytics data
- configure IAM permissions at the project and dataset level
- authenticate dbt and Python tooling with a service account instead of personal user credentials

This project configures the dbt service-account profile in [profiles.example.yml](profiles.example.yml), with environment values in [.env.example](.env.example). Before local use, both files must be renamed and populated with the correct project-specific values so dbt and the Python tooling authenticate against the right environment.

## S3 and bucket storage pattern

The broader platform design includes a layered storage pattern for raw and staged data, with cloud storage buckets dedicated to distinct functions:
- raw landing files
- processed or staged files
- archive or retained source snapshots

Even though this dbt project targets BigQuery, the surrounding architecture follows the same pattern used in S3-based ecosystems: separate buckets by purpose, enforce permissions by role, and preserve a clean boundary between raw ingestion and curated analytics data.

## Service account setup

The recommended setup for this project is as follows:

1. Create a service account in Google Cloud IAM.
2. Grant the minimum necessary BigQuery and storage roles for the project and datasets.
3. If the workflow reads files from object storage or uses Python-based ingestion, add the required Storage permissions as needed.
4. Generate a JSON key for the service account and store it securely.
5. Set the required environment variables:
   - GOOGLE_APPLICATION_CREDENTIALS
   - DBT_RAW_PROJECT_ID
   - DBT_RAW_DATASET_ID
6. Point dbt to the service account key in the profile and validate connectivity with dbt debug.

A working example appears in [.env.example](.env.example) and [profiles.example.yml](profiles.example.yml). These are example files only; they need to be renamed to the actual local filenames used by the tooling and filled in with the correct GCP project, dataset, and service-account path before the project runs locally.

## Local environment management with direnv

Local environment variables are managed with `direnv` so credentials and project settings stay out of the repo and remain easy to switch per environment.

This pattern keeps the setup consistent across local development:
- load the .env or .envrc file automatically when entering the project directory
- provide project-scoped secrets without committing them to source control
- keep dbt and Python scripts aligned with the same credentials and dataset settings

For local work, use the project environment file as the source of truth for service-account paths, raw project IDs, and dataset names. The project includes a dotenv-style example in [.env.example](.env.example), and the intended workflow is to copy and rename it to the real local environment file before running any dbt or Python commands.

## dbt Cloud and trigger automation

The stack includes dbt Cloud, which serves as the orchestration layer for production runs and deployment automation. The repository also includes a helper script, [tools/dbt-trigger](tools/dbt-trigger), which triggers a dbt Cloud production environment for execution.

This script is useful when a developer wants to start a dbt Cloud job without manually opening the UI, making it easy to move from local validation to cloud execution in a repeatable way.

## Project structure

- [models/](models/) — dbt staging, intermediate, and mart models
- [seeds/](seeds/) — seed files and reference datasets
- [snapshots/](snapshots/) — snapshot definitions
- [analyses/](analyses/) — ad hoc SQL checks and validation queries
- [macros/](macros/) — reusable dbt macros
- [functions/](functions/) — SQL and UDF helper objects
- [tools/](tools/) — data generation, loading, and trigger utilities
- [tests/](tests/) — SQL-based dbt tests

## Quick start

1. Create and activate a Python environment.
2. Install dependencies:
   `python -m pip install -r requirements.txt`
3. Install dbt dependencies if needed:
   `dbt deps`
4. Copy the example profile and env file, then fill in your project values.
5. Validate and run the project:
   `dbt debug`
   `dbt build`

## Raw data generation and loading

This project includes a generator/loading utility at [tools/gen_load.py](tools/gen_load.py). The script automates the Jaffle Shop raw-data workflow by generating synthetic CSV files, placing them in a configured data directory, and loading them into BigQuery using the configured service account.

The project is designed to support fast iteration: the Python script and shell helpers make it easy to regenerate raw data, reload test datasets, validate transformations, and rerun targeted checks without a long setup cycle. This is especially useful during local development and dbt test loops.

For more detail on the script, its environment variables, and example commands, see [tools/README.md](tools/README.md).

## Related documentation

- [tools/README.md](tools/README.md)
- [tools/gen_load.py](tools/gen_load.py)
- [tools/dbt-trigger](tools/dbt-trigger)
- [profiles.example.yml](profiles.example.yml)
- [.env.example](.env.example)
- [dbt_project.yml](dbt_project.yml)

## Resources

- dbt docs: https://docs.getdbt.com/docs/introduction
- dbt Discourse: https://discourse.getdbt.com/
- Jaffle Shop generator: https://github.com/dbt-labs/jaffle-shop-generator
