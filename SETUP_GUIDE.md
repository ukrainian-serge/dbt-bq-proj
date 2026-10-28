# Setup Guide

## 1. GCP Service Accounts

Create two service accounts in your GCP project:

**Dev (local development + CI):**
- Roles: `bigquery.admin`, `bigquery.dataEditor`, `bigquery.jobUser`, `storage.objectAdmin`
- Download JSON key and save to secure location

**Prod (dbt Cloud):**
- Roles: `bigquery.admin`, `bigquery.dataEditor`, `bigquery.jobUser`
- Generate API key in dbt Cloud and configure with this account

## 2. BigQuery Setup

- Create `raw` dataset (for source tables)
- Create `analytics` dataset (for dbt models)
- Both should be in the same GCP project for dev and prod environments

## 3. dbt Profiles

Add to `~/.dbt/profiles.yml`:

```yaml
jaffle_shop:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: YOUR-GCP-PROJECT
      dataset: analytics
      keyfile: /path/to/dev-key.json
      threads: 4
      location: US
```

## 4. Environment Variables

Create `.envrc` in project root:

```bash
export VIRTUAL_ENV="$PWD/env"
PATH_add env/bin

# For raw data loading
export DBT_GCP_LOADER_KEY="$HOME/.config/gcp/dev-key.json"
export DBT_GCP_PROJECT_ID="YOUR-GCP-PROJECT"
export DBT_BQ_DATASET_RAW="raw"
```

Run `direnv allow` to auto-load on directory entry.
