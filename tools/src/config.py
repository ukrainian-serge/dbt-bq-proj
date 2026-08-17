from dataclasses import dataclass
import pandas as pd
import os
from pathlib import Path
from datetime import datetime
from google.cloud import bigquery
from google.oauth2 import service_account
from dotenv import load_dotenv
import typer
from typing import Optional


CONFIG_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = CONFIG_DIR.parents[1]  # Adjust based on directory depth
ENV_PATH = PROJECT_ROOT / ".env"
DEFAULT_DATA_DIR = PROJECT_ROOT / "jaffle_raw_data"


@dataclass(frozen=False)
class Config:
# 1. Populated from environment variables (.env) via load_config()
    project_id: str
    dataset_id: str
    key_path: Path

    # 2. Populated from Typer CLI flags in main()
    write_disposition: str = "WRITE_TRUNCATE"
    generate: bool = False
    prefix: str = "raw"
    data_dir: Path = Path("./data")

# Annotate as datetime directly without Optional
    date_from: datetime = datetime.now()
    date_to: datetime = datetime.now()

    # 3. Attached during BigQuery setup
    client: Optional[bigquery.Client] = None
    dataset_ref: Optional[str] = None

    calculated_years: Optional[int] = None

    s_dst: pd.Series | None = None

    order_unique_id: pd.arrays.ArrowStringArray | None = None
    order_unique_cust: pd.arrays.ArrowStringArray | None = None



def load_config() -> Config:
    """Loads .env and validates required configuration."""
    if ENV_PATH.exists():
        load_dotenv(dotenv_path=ENV_PATH, override=True)

    key_path = os.getenv("GOOGLE_DEV_CREDENTIALS")
    project_id = os.getenv("GCP_PROJECT_ID")
    dataset_id = os.getenv("BQ_DATASET_ID")
    raw_data_dir = os.getenv("JAFGEN_DATA_DIR")

    # 1. Validation & Early Exit
    if not key_path or not project_id or not dataset_id:
        missing = []
        if not key_path: missing.append("GOOGLE_DEV_CREDENTIALS")
        if not project_id: missing.append("GCP_PROJECT_ID")
        if not dataset_id: missing.append("BQ_DATASET_ID")
        typer.echo(f"❌ Missing required environment variables: {', '.join(missing)}", err=True)
        raise typer.Exit(code=1)

    # 2. Convert and resolve paths safely
    key_path = Path(key_path).expanduser().resolve()
    
    if not key_path.exists():
        typer.echo(f"❌ Service account key file not found at: {key_path}", err=True)
        raise typer.Exit(code=1)

    # 3. Explicitly construct data_dir Path
    if raw_data_dir:
        data_dir = Path(raw_data_dir).expanduser().resolve(strict=False)
    else:
        data_dir = DEFAULT_DATA_DIR.resolve(strict=False)

    # Pyright now recognizes key_path, project_id, dataset_id, and data_dir 
    # as strictly matching the Config class dataclass types.
    return Config(
        key_path=key_path,
        project_id=project_id,
        dataset_id=dataset_id,
        data_dir=data_dir
    )


def get_bigquery_client(cfg: Config) -> None:
    """Retrieves BigQuery client and ensures target dataset exists."""
    credentials = service_account.Credentials.from_service_account_file(cfg.key_path)
    client = bigquery.Client(credentials=credentials, project=cfg.project_id)

    dataset_ref = f"{cfg.project_id}.{cfg.dataset_id}"

    try:
        client.get_dataset(dataset_ref)
        print(f"🔍 Dataset '{dataset_ref}' exists.")
    except Exception:
        print(f"⚠️ Dataset '{dataset_ref}' not found. Creating it...")
        client.create_dataset(bigquery.Dataset(dataset_ref))
        print(f"✅ Dataset '{dataset_ref}' created.")

    cfg.client = client
    cfg.dataset_ref = dataset_ref
# 