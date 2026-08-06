#!/usr/bin/env python3

import os
import sys
from dotenv import load_dotenv
from pathlib import Path
import pandas as pd
from google.cloud import bigquery
from google.oauth2 import service_account

project_root = Path(__file__).resolve().parents[1]
env_path = project_root / ".env"

# Prefer values already exported by the shell/direnv environment.
# Fall back to a dotenv file only if those variables are not present.
if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
    load_dotenv(env_path)

KEY_PATH = os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or os.getenv("GOOGLE_APPLICATION_CREDENTIALS_DEV")
PROJECT_ID = os.getenv("DBT_RAW_PROJECT_ID") or os.getenv("DBT_PROJECT_ID")
DATASET_ID = os.getenv("DBT_RAW_DATASET_ID") or os.getenv("DBT_DATASET_ID")
DATA_DIR = os.getenv("DBT_DATA_DIR", "data")

print(f"🔍 Loading environment from: {env_path}")
print(f"🔍 File exists: {env_path.exists()}")



def load_data_to_bigquery():
    # 1. Authenticate
    try:
        credentials = service_account.Credentials.from_service_account_file(KEY_PATH)
        client = bigquery.Client(credentials=credentials, project=PROJECT_ID)
        print(f"✅ Authenticated as {credentials.service_account_email}")
    except Exception as e:
        print(f"❌ Authentication failed: {e}")
        return

    # 2. Ensure Dataset Exists
    dataset_ref = f"{PROJECT_ID}.{DATASET_ID}"
    try:
        client.get_dataset(dataset_ref)
        print(f"Dataset '{DATASET_ID}' exists.")
    except Exception:
        print(f"Dataset '{DATASET_ID}' not found. Creating it...")
        dataset = bigquery.Dataset(dataset_ref)
        client.create_dataset(dataset)
        print(f"Dataset '{DATASET_ID}' created.")

    # 3. Iterate and Load
    for csv_path in Path(DATA_DIR).glob("*.csv"):

        table_name = csv_path.stem.split('_')[-1]
        
        try:
            # Load CSV into DataFrame
            df = pd.read_csv(csv_path, dtype=str)

            print(df.head(1))  # Print first few rows for verification
            
            # Configure Load Job
            job_config = bigquery.LoadJobConfig(
                write_disposition="WRITE_TRUNCATE",
                autodetect=True, # Let BigQuery infer schema from the DataFrame data
            )

            table_ref = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"
            
            # Load data
            job = client.load_table_from_dataframe(df, table_ref, job_config=job_config)
            job.result()  # Wait for the job to complete

            print(f"   Success: Loaded {len(df)} rows into `{table_ref}`")

        except Exception as e:
            print(f"   Error loading {csv_path.name}: {e}")

if __name__ == "__main__":
    load_data_to_bigquery()   