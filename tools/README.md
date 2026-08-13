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

### Quick Start (Recommended)

Generate and load data within a specific date range:

```bash
# Generate data for 90 days (auto-calculates 1 year generation, filters to range)
python tools/gen_load.py --generate --daterange-from 2026-05-15 --daterange-to 2026-08-12

# Generate data for 2 years worth of transactions in a 6-month window
python tools/gen_load.py --generate --daterange-from 2026-02-12 --daterange-to 2026-08-12

# Generate 1 year without date filtering
python tools/gen_load.py --generate --years 1
```

### How It Works

When you provide a date range with `--daterange-from` and `--daterange-to`:

1. **Calculate**: Script calculates years to generate (365 days per year)
2. **Generate**: jafgen creates that many years of data
3. **Filter**: Only rows with dates within your range are kept

**Example**: 90-day window (2026-05-15 to 2026-08-12)
```
Input: --daterange-from 2026-05-15 --daterange-to 2026-08-12
Calculation: 89 days → 1 year needed
Generated: Full year of data from jafgen
Filtered: Only rows with dates between 2026-05-15 and 2026-08-12
Result: 90 days of realistic transaction data within your range
```

### Additional Usage Examples

```bash
# Load existing CSVs with date range filtering
python tools/gen_load.py --daterange-from 2026-06-12 --daterange-to 2026-08-12

# Append more data
python tools/gen_load.py --generate --years 1 --write-disposition WRITE_APPEND

# Load without date filtering
python tools/gen_load.py
```

The script reads values from the environment and a dotenv file (`.env` in the project root). The expected variables are:

```bash
GOOGLE_APPLICATION_CREDENTIALS=/path/to/your-service-account.json
DBT_RAW_PROJECT_ID=your-raw-project-id
DBT_RAW_DATASET_ID=your-raw-dataset
DBT_DATA_DIR=data/
```

## Date Range Filtering

When you provide `--daterange-from` and `--daterange-to`:

- Creates a date spine from both dates (inclusive)
- Filters all rows to only keep those with dates within the range
- Works on all datetime columns (`ordered_at`, `tweeted_at`, etc.)

**Why this approach**:
- ✅ Preserves realistic transaction patterns within your date window
- ✅ No data transformation—just date-based row filtering
- ✅ Works with existing data or freshly generated data
- ✅ Keeps all relative relationships intact (customer lifetime, order sequences)

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
