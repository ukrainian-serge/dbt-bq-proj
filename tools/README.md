# Data Generation and Loading

Local utility for generating synthetic Jaffle Shop data and loading into BigQuery. **Note:** This is a temporary dev tool; see [NOTES.md](../NOTES.md) for the roadmap to replace this with a proper data loader (dlt, Fivetran, or similar).

## Quick Start

```bash
# Generate and load data for a date range
python tools/gen_load.py --generate --date-from 2026-05-15 --date-to 2026-08-12

# Load existing CSVs with date filtering
python tools/gen_load.py --date-from 2026-06-12 --date-to 2026-08-12

# Append more data
python tools/gen_load.py --generate --date-from 2026-08-13 --date-to 2026-08-17 --write-disposition WRITE_APPEND
```

## How it works

1. **Generate** — Creates synthetic Jaffle Shop CSVs using `jafgen`
2. **Filter** — Applies date-range filtering to preserve realistic transaction patterns
3. **Load** — Authenticates with GCP service account and loads into BigQuery

Requires environment variables from `.envrc`:
- `DBT_GCP_LOADER_KEY` — Service account JSON path
- `DBT_GCP_PROJECT_ID` — GCP project ID
- `DBT_BQ_DATASET_RAW` — Target BigQuery dataset

See [SETUP_GUIDE](../SETUP_GUIDE.md) for configuration.

## Future: Data Loader Transition

This synthetic data tool is **deprecated** in favor of a proper ELT/ETL loader:
- **Target:** dlt, Fivetran, or Airbyte
- **Architecture:** Containerized on GCP (Cloud Run + Cloud Scheduler or Composer)
- **Goal:** Real or realistic external data in the raw layer, owned by the loader, not by dbt

See [NOTES.md](../NOTES.md) for details.
