# Module Overview

Core modules for `gen_load.py`:

## config.py
Loads environment configuration and initializes BigQuery client.
- Reads env variabls (project_id, dataset_id, service account key path)
- Stores CLI flags and state in `Config` dataclass
- Creates BigQuery client

## generate.py
Generates synthetic data and handles date filtering.
- Runs `jafgen.Simulation` to create raw CSVs
- Maps and filters data to specified date range
- Saves results to `data_dir`

## process_dates.py
Date validation and range processing.
- Parses and validates YYYY-MM-DD date strings
- Calculates years needed based on date range
- Generates date series for data filtering

## loader.py
Loads CSVs into BigQuery.
- Validates all columns are string type
- Configures BigQuery load job
- Loads DataFrames to tables with write disposition (WRITE_TRUNCATE or WRITE_APPEND)
