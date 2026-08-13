# Data Generation and Loading Utilities

This directory contains the tooling used to generate sample Jaffle Shop data, load it into BigQuery, and trigger dbt Cloud jobs for production-style execution.

## What the script does

The main script, [gen_load.py](gen_load.py), performs two main tasks:

1. Generates synthetic raw CSV files using the `jafgen` simulation library.
2. Loads those CSV files into a BigQuery dataset using a Google service account.

It is intended to make the raw-data phase of the project repeatable and easy to run from a local environment without manual CSV uploads.

## Workflow

The script can run in either of these modes:

- generate only data
- generate data and load it to BigQuery
- load existing CSVs from a configured directory

Typical usage looks like this:

```bash
python tools/gen_load.py --generate --years 1 --prefix raw --data-dir tools/data
python tools/gen_load.py --write-disposition WRITE_TRUNCATE
```

The script reads values from the environment and a dotenv file (`.env` in the project root). The expected variables are:

```bash
GOOGLE_APPLICATION_CREDENTIALS=/path/to/your-service-account.json
DBT_RAW_PROJECT_ID=your-raw-project-id
DBT_RAW_DATASET_ID=your-raw-dataset
DBT_DATA_DIR=data/
```

## How it works

- `generate_jaffle_data()` creates a temporary simulation workspace and writes CSVs into the configured data directory.
- `load_data_to_bigquery()` authenticates using the service account JSON file.
- It creates the target dataset in BigQuery if it does not already exist.
- Each CSV file is read, autodetected into a BigQuery table, and loaded using the chosen write disposition.

## BigQuery and service-account integration

This script expects a Google Cloud service account credential file and uses the Google BigQuery Python client to authenticate and load data.

## dbt Cloud trigger helper

The repository also includes [dbt-trigger](dbt-trigger), a shell utility for starting a dbt Cloud job from the local terminal. This script is designed for the production path when the project runs through dbt Cloud rather than only local dbt commands.

It looks for the dbt Cloud identifiers and API token in the credentials environment file and then calls the dbt Cloud v2 job run endpoint:

```bash
./tools/dbt-trigger -c /path/to/credentials.env
./tools/dbt-trigger -m "manual run from local dev" -c /path/to/credentials.env
```

The script expects values such as:

```bash
DBT_CLOUD_ACCOUNT_ID=12345
DBT_CLOUD_JOB_ID=67890
DBT_CLOUD_HOST=cloud.getdbt.com
DBT_CLOUD_API_TOKEN=your_token_here
```

This makes it easy to quickly kick off a dbt Cloud production job after local validation, while keeping the trigger logic simple and repeatable.

## Notes

- The script uses `WRITE_TRUNCATE` by default, which replaces existing rows in target tables on reload, but `WRITE_APPEND` is available for incremental testing.
- The generated data is meant for development and demo work, not production-grade data modeling.
- If you are using a custom data directory or a different raw project, update the applicable environment variables before running the loader.

## Related documentation

- [../README.md](../README.md)
- [../profiles.example.yml](../profiles.example.yml)
- [../.env.example](../.env.example)
