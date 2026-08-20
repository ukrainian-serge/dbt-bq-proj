# Data Generation and Loading

Generates synthetic Jaffle Shop data and loads it into BigQuery.

## Quick Start

```bash
# Generate and load data for a date range
python tools/gen_load.py --generate --date-from 2026-05-15 --date-to 2026-08-12

# Load existing CSVs without generating
python tools/gen_load.py --data-dir ./jaffle_raw_data

# Use existing, but map and filter by date-from and date-to
python tools/gen_load.py --data-dir --date-from 2026-05-15 --date-to 2026-08-12
```

## gen_load.py

Entry point that orchestrates data generation and loading:
- Uses `jafgen` to generate synthetic Jaffle Shop CSVs
- Maps dates and filters data to specified date range
- Loads CSVs into BigQuery tables

Requires `.envrc` with: `GCP_SA_PROD_CREDS`, `BQ_RAW_PROJECT_ID`, `BQ_RAW_DATASET`, `JAFGEN_DATA_DIR`


See [src/](src/) for module details.

```

### Additional Usage Examples

```bash
# Load existing CSVs with date range filtering
python tools/gen_load.py --date-from 2026-06-12 --date-to 2026-08-12

# Append more data
python tools/gen_load.py --generate --date-from 2026-08-13 --date-to 2026-08-17 --write-disposition WRITE_APPEND

# Load without date filtering
python tools/gen_load.py
```

The script reads values from the environment, which are set by `.envrc` via direnv.

```bash
# .envrc
...
GCP_SA_RAW_CREDS=/path/to/your-service-account.json
BQ_RAW_PROJECT_ID=your-raw-project-id
BQ_RAW_DATASET=your-raw-dataset
JAFGEN_DATA_DIR=jaffle_raw_data/
...
```

## Date Range Filtering

When you provide `--date-from` and `--date-to`:

- Creates a date spine from both dates (inclusive)
- Filters all rows to only keep those with dates within the range
- USes and applies to `orders.csv` and `tweets.csv`

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

This script expects a Google Cloud service account credential file and uses the Google BigQuery Python client to authenticate and load data. See **[SETUP_GUIDE](.SETUP_GUIDE.md)**

## dbt Cloud trigger helper

The repository also includes [dbt-trigger](dbt-trigger), a shell utility for starting a dbt Cloud job from the local terminal. This script is designed for the production path when the project runs through dbt Cloud rather than only local dbt commands.

It looks for the dbt Cloud identifiers and API token in the credentials environment file and then calls the dbt Cloud v2 job run endpoint:

```bash
./tools/dbt-trigger -c /path/to/credentials
./tools/dbt-trigger -m "manual run from local dev" -c /path/to/credentials
```

The script expects values such as:

```bash
DBT_CLOUD_ACCOUNT_ID=12345
DBT_CLOUD_JOB_ID=67890
DBT_CLOUD_HOST=cloud.getdbt.com
DBT_CLOUD_API_TOKEN=your_token_here
```

This makes it easy to quickly kick off a dbt Cloud production job after local validation, while keeping the trigger logic simple and repeatable.

## Related documentation
 
- **[SETUP_GUIDE](../SETUP_GUIDE.md)** 
- [../README.md](../README.md)
