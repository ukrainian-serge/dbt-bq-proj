# NOTES – Making dbt-bq-proj production-grade

## Data ingestion (replace `tools/gen_load.py`)
- Current: local Python script generates synthetic CSVs and loads them into BigQuery.
- Target: external, professional loader owns the raw layer.
  - Prefer dlt (or Airbyte / Fivetran) pulling from real APIs.
  - Land data in a raw dataset; dbt sources point at those tables.
  - Can be containerized and scheduled on GCP (Cloud Run, Cloud Scheduler, or Composer).
- Still need a good free public API (or set of APIs) for realistic source data.

## Orchestration (replace `tools/dbt-trigger`)
- Current: local script calls dbt Cloud API to kick a production job.
- Target: standard GitHub + dbt Cloud flow.
  1. PR against `main` → dbt Cloud CI job  
     (slim build, `state:modified+`, defer to prod, temp schema).
  2. Merge to `main` → production job runs automatically  
     (scheduled or on-merge trigger).
- Optional local helper: `prod-manifest-pull` only for `--defer --state` during development.  
  It does not replace the CI → prod pipeline.

## What stays the same
- dbt models, tests, YAML, macros, project structure.
- BigQuery as the warehouse.
- dbt Cloud as the orchestrator for dbt jobs.

## Open items
- Choose free public API(s) for the loader.
- Decide GCP runtime for the loader (Cloud Run + Scheduler is the usual lightweight choice).
- Configure dbt Cloud CI + prod environments and jobs to match the PR/merge flow.