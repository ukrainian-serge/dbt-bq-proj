# dbt Project

Jaffle Shop analytics stack built with dbt Core and BigQuery on Google Cloud Platform. Models are organized by layer (staging → intermediate → marts), with enforced contracts on key fact tables.

See **[SETUP_GUIDE](./SETUP_GUIDE.md)** for environment setup.

## Stack

- **Warehouse:** BigQuery (GCP)
- **Transformation:** dbt Core (local dev) and dbt Cloud (production/CI)
- **Authentication:** Google Cloud service accounts
- **Orchestration:** dbt Cloud (prod job triggers, CI runs on PR)

## Project structure

**Staging** → **Intermediate** → **Marts**

- [models/staging/](models/staging/) — Clean normalized views of raw tables  
- [models/marts/intermediate/](models/marts/intermediate/) — Business logic joins and aggregations  
- [models/marts/fact/](models/marts/fact/) — Fact tables for analytics (contract enforced)  
- [models/legacy/](models/legacy/) — Backward-compatible legacy models  
- [macros/](macros/) — Reusable SQL logic  
- [tests/](tests/) — dbt tests (schema and data validation)

## Quick start

1. Set up GCP service accounts and BigQuery datasets
2. Create Python environment: `python -m venv env && source env/bin/activate`
3. Install dependencies: `pip install -r requirements.txt && dbt deps`
4. Configure `~/.dbt/profiles.yml` with BigQuery credentials (see [SETUP_GUIDE](./SETUP_GUIDE.md))
5. Load raw data: `python tools/gen_load.py --generate --date-from 2026-05-15 --date-to 2026-08-12`
6. Build dbt models: `dbt build`

## Documentation

- **[SETUP_GUIDE](./SETUP_GUIDE.md)** — GCP and dbt configuration
- **[NOTES.md](./NOTES.md)** — Future roadmap (data loader, orchestration)
- [dbt_project.yml](dbt_project.yml) — Project config and variables