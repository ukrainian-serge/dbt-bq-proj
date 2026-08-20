# Project Setup Guide

This document provied necessary and optional set up instructions for env files, debug and testing, and prod execution of dbt.

---

## 1. GCP Project and Service Account Setup:

**How to set up**:  
1. Create GCP Project for your work.
2. Create a service account for `DEV`.  
The below is the roles and permssions I set up, I was indiscriminate, you could probably walk them back a bit:    
    ```bash
    ------------------------------------------
    dbt Dev Service Account Roles (dev-sa-account@your-project-id.iam.gserviceaccount.com)
    ------------------------------------------
    roles/aiplatform.colabEnterpriseUser
    roles/aiplatform.notebookRuntimeUser
    roles/aiplatform.user
    roles/bigquery.admin
    roles/bigquery.dataEditor
    roles/bigquery.jobUser
    roles/dataproc.editor
    roles/dataproc.serverlessEditor
    roles/storage.objectAdmin
    ```
3. If you need to set up your `mcp.json` for Ai Agent help, these are the ones I set up. Very minimal:

    ```bash
    ------------------------------------------
    Ai Agent BQ Reader Roles (ai-sa-account@your-project-id.iam.gserviceaccount.com)
    ------------------------------------------
    roles/bigquery.dataViewer
    roles/bigquery.metadataViewer
    ```


## 2. dbt Profiles Configuration

**File location:** `~/.dbt/profiles.yml`   

```yaml
# profiles.yml
jaffle_shop:
target: dev
outputs:
  dev:
    type: bigquery  # We are using BigQuery for this course
    method: service-account  # Authentication method
    project: YOUR-DEV-PROJ  # BigQuery project ID from Google Cloud Console
    dataset: YOUR-DEV-DATASET  # Dataset name where dbt will create tables/views
    keyfile: /path/to/creds.json  # Path to your service account key JSON file
    threads: 4
    location: US
```


---

## 3. Environment Variables Setup

**File location:** `.envrc` in project root.



```bash
# .envrc

# Dev / Default Environment (Used by dbt, Python, & VS Code mcp.json)
export GCP_SA_DEV_CREDS="/path/to/prod-service-account.json"
export BQ_DEV_PROJECT_ID="your-dev-proj"
export BQ_DEV_DATASET="your-dev-dataset"

# Raw/Source setup. Needed for gen_load.py
export GCP_SA_RAW_CREDS="/path/to/raw-service-account.json" 
export BQ_RAW_PROJECT_ID="your-raw-proj"
export BQ_RAW_DATASET="your-raw-dataset"
export JAFGEN_DATA_DIR="jaffle_raw_data/"

# Production Environment (Optional local reference)
export GCP_SA_PROD_CREDS="/path/to/prod-service-account.json"
export BQ_PROD_PROJECT_ID="your-prod-proj"
export BQ_PROD_DATASET="your-prod-dataset"


# Agent Service Account(Keep minimal roles and permissions)
export GCP_SA_AGENT_CREDS="/path/to/agent-service-account.json"

PATH_add tools # add pathing to tools/          
source env/bin/activate # activate python env
source_env $HOME/keys/dbt_cloud_credentials # (Optional) Import for dbt Cloud

# (Optional) just in case you need a .env
# env | grep -E '^(GCP_SA_|BQ_|JAFGEN_)' > .env 

```


---

## 4. dbt Cloud Credentials (Optional)

**File location:** `~/keys/dbt_cloud_credentials`

**How to set up:**  
1. Obtain your dbt Cloud credentials from your dbt Cloud account
2. Either:
   - Create a `~/keys/dbt_cloud_credentials` file. `direnv` autoloads, OR 
   - Export these as environment variables in your shell config (`.bashrc`, `.zshrc`, etc.)

**File contents:**

```bash
export DBT_CLOUD_ACCOUNT_ID="123456"  # Your dbt Cloud account ID
export DBT_CLOUD_JOB_ID="789012"  # Job ID for triggering runs
export DBT_CLOUD_API_TOKEN="dbtc_xxxxxxxxx"  # Your dbt Cloud API token (keep secret!)
export DBT_CLOUD_HOST="cloud.getdbt.com"  # dbt Cloud hostname
```

---


## 5. VS Code Debug Configuration (Optional)

**File location:** `.vscode/launch.json`    

**How to set up:**
If you want to develop `tools/gen_load.py` further, this might be helpful for debug:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "debugpy",
            "request": "launch",
            "program": "${workspaceFolder}/tools/gen_load.py",
            "args": [
                "-g",
                "-f", "2018-01-01",
                "-t", "2026-08-01",
                "-w", "WRITE_TRUNCATE"
            ],
            "console": "integratedTerminal",
            "justMyCode": true
        }
    ]
}
```

---

## 6. MCP (Model Context Protocol) Configuration (Optional)

**File location:** `.vscode/mcp.json`  


```json
{
  "servers": {
    "dbt": {
      "command": "dbt-core-mcp", 
      "args": [
        "--project-dir",
        "${workspaceFolder}"
      ]
    },
    "bigquery": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-bigquery"
      ],
      "env": {
        "BIGQUERY_PROJECT_ID": "{env:BQ_DEV_PROJECT_ID}",
        "GOOGLE_APPLICATION_CREDENTIALS": "{env:GCP_SA_AGENT_CREDS}" 
      }
    }
  }
}
```

## Summary Checklist
- [ ] GCP Project and Service Accounts Setup
- [ ] dbt Profiles Configuration `~/.dbt/profiles.yml`
- [ ] Create `.envrc`, and optionally, `.env`
- [ ] (Optional) `.vscode/mcp.json`
- [ ] (Optional) Set up dbt Cloud credentials in `~/.dbt/dbt_cloud_credentials`
- [ ] (Optional) Configure `.vscode/launch.json` with debug settings

---
