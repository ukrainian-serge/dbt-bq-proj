# dbt Project

This project builds a Jaffle Shop-style analytics stack with dbt Fusion, BigQuery, and a lightweight local developer workflow. The model layer covers staging, intermediate logic, and marts, while the surrounding setup supports raw-data generation, service-account authentication, and dbt Cloud-triggered production runs.

See **[SETUP_GUIDE](./SETUP_GUIDE.md)**

## Project overview

The repository includes:
- Python utilities for raw-data generation and BigQuery ingestion
- dbt models for staging, intermediate, and analytics marts
- local environment management through direnv
- a dbt Cloud-compatible workflow for production job triggers
- mcp setup for linking Ai Agent to GCP

## Stack and cloud architecture

This stack centers on dbt Cloud for orchestration, with BigQuery as the warehouse and Google Cloud Platform as the underlying infrastructure. 
The project follows a modern ELT pattern:
- raw data files generated via [tools/gen_load.py](tools/gen_load.py) and loaded into bq
- dbt transforms and models the data into curated reporting tables
- dbt jobs in dbt Cloud trigger and orchestrate the production workflow

This setup makes the project a good example of how local development, cloud data engineering, and deployment automation fit together in a real analytics environment.

## GCP and BigQuery setup

The environment follows a standard Google Cloud setup:
- create or select a GCP project
- enable the required APIs, especially BigQuery
- create separate datasets for raw ingestion and transformed analytics data
- configure IAM permissions at the project and dataset level

## Local environment management with direnv

Local environment variables are managed with `direnv` so credentials and project settings stay out of the repo and remain easy to switch per environment.

This pattern keeps the setup consistent across local development:
- load the `.env` or `.envrc` files automatically when entering the project directory
- provide project-scoped secrets without committing them to source control
- keep dbt and Python scripts aligned with the same credentials and dataset settings

## Raw data generation and loading

This project includes a generator/loading utility at [tools/gen_load.py](tools/gen_load.py). The script automates the Jaffle Shop raw-data workflow by generating synthetic CSV files, placing them in a configured data directory, and loading them into BigQuery using the configured service account.

The project is designed to support fast iteration: the Python script and shell helpers make it easy to regenerate raw data, reload test datasets, validate transformations, and rerun targeted checks without a long setup cycle. This is especially useful during local development and dbt test loops.

For more detail on the script, its environment variables, and example commands, see [tools/README.md](tools/README.md).

## dbt Cloud and trigger automation

The stack includes dbt Cloud, which serves as the orchestration layer for production runs and deployment automation. The repository also includes a helper script, [tools/dbt-trigger](tools/dbt-trigger), which triggers a dbt Cloud production environment for execution.

This script is useful when a developer wants to start a dbt Cloud job without manually opening the UI, making it easy to move from local validation to cloud execution in a repeatable way.

## Project structure

### dbt models
Located in [models/](models/) and organized by layer:

**Staging** (`staging/`)
- Raw data layer that sources from the Jaffle Shop source tables and creates clean, normalized views:
  - `stg_jaffle_shop__customers` — Customers staging view with unique/not_null tests on customer_id
  - `stg_jaffle_shop__orders` — Orders staging view with referential integrity to customers
  - `stg_jaffle_shop__items` — Order items staging view
  - `stg_jaffle_shop__products` — Products staging view
  - `stg_jaffle_shop__stores` — Stores staging view
  - `stg_jaffle_shop__supplies` — Supplies staging view
  - `stg_jaffle_shop__tweets` — Tweets staging view

**Intermediate** (`marts/intermediate/`)
- Business logic and joins combining staging data with aggregations:
  - `int_customer_orders` — Enriched orders with customer-level aggregations (contract enforced), includes transaction sequencing and lifetime value calculations
  - `int_store_products` — Store-product relationships

**Marts** (`marts/fact/`)
- Fact tables for analytics:
  - `fct_customer_orders` — Primary fact table with **two versions** (v1 and v2) using incremental microbatch materialization, partitioned by order date, with contract enforcement and public access. v2 refines datetime columns (fdos, payment_finalized_date) to date types.
  - `fct_test` — Testing endpoint (assigned to product group)

**Legacy** (`legacy/`)
- Backward-compatible models maintained for historical reference:
  - `fct_customer_orders_legacy` — Previous fact table implementation with comprehensive data tests (unique/not_null constraints, accepted values for nvsr)

**Python Models** (`python_demo/`)
- Experimental Python-based models (**disabled by default** in dbt_project.yml; they require 20+ minutes startup time):
  - `dates_spine` — Date spine helper table (SQL-based)
  - `is_holiday` — Python model for holiday detection using pandas and holidays packages

### Additional dbt directories
- [seeds/](seeds/) — seed files and reference datasets (disabled by default)
- [snapshots/](snapshots/) — snapshot definitions
- [analyses/](analyses/) — ad hoc SQL checks and validation queries (disabled by default)
- [macros/](macros/) — reusable dbt macros (e.g., `clean_zero_row_models`)
- [functions/](functions/) — SQL and UDF helper objects
- [tests/](tests/) — SQL-based dbt tests with dbt_utils for cardinality and equality validations

### Development and tooling
- [tools/](tools/):
   - (pre-dbt DEV) `gen_load.py`: raw data generation and BigQuery loading
   - (dbt PROD) `dbt-trigger`: dbt Cloud production job API trigger

## Quick start

1. Setup GCP service accounts and projects.
2. Create python environment.
3. Install dependencies:
   `python -m pip install -r requirements.txt`
4. Install dbt dependencies if needed:
   `dbt deps`
5. Generate data following this [tools/README.md](tools/README.md)
6. dbt models building:
   `dbt debug`
   `dbt build`

## Related documentation

- **[SETUP_GUIDE](./SETUP_GUIDE.md)**
- [tools/README.md](tools/README.md)
- [tools/gen_load.py](tools/gen_load.py)
- [tools/dbt-trigger](tools/dbt-trigger)
- [dbt_project.yml](dbt_project.yml)

## Resources

- dbt docs: https://docs.getdbt.com/docs/introduction
- dbt Discourse: https://discourse.getdbt.com/
- Jaffle Shop generator: https://github.com/dbt-labs/jaffle-shop-generator