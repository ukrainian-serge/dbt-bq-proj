# NOTES – Production Roadmap

## Current Setup

✅ **Warehouse:** BigQuery (GCP)  
✅ **Transformation:** dbt Core (local dev) + dbt Cloud (prod/CI)  
✅ **Authentication:** Google Cloud service accounts  
✅ **Schemas:** Separate raw and analytics datasets per environment  

## Planned Transitions

### 1. Data Loader (Q1 2027)

**Current:** `tools/gen_load.py` — synthetic data generator (local, temporary)

**Target:** Replace with production-grade loader
- **Tool:** dlt, Fivetran, or Airbyte
- **Architecture:** Containerized on GCP (Cloud Run + Cloud Scheduler or Composer)
- **Data source:** Real or realistic external APIs (TBD)
- **Responsibility:** Loader owns raw layer; dbt sources point to loader-managed tables
- **Benefit:** Separates data ingestion from transformation; removes synthetic-only workflow

**Status:** In planning. Blocked on choosing data source APIs.

### 2. Orchestration (Q1-Q2 2027)

**Current:** `tools/dbt-trigger` — local script for triggering dbt Cloud jobs

**Target:** GitHub + dbt Cloud native CI/CD
- **CI:** PR against `main` → dbt Cloud CI job (slim build, state-deferred, temp schema)
- **Prod:** Merge to `main` → production job runs automatically (scheduled or on-merge)
- **Local dev:** No changes; dbt CLI works as-is

**Status:** Awaiting dbt Cloud CI/prod job configuration.

## Staying the Same

- dbt models, tests, macros, YAML structure
- BigQuery as the warehouse
- dbt Cloud as the orchestration layer
- Service account authentication via GCP IAM