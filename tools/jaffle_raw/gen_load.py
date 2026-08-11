#!/usr/bin/env python3

import os
import shutil
import tempfile
from pathlib import Path
from typing import Literal

import pandas as pd
import typer
from dotenv import load_dotenv
from google.cloud import bigquery
from google.oauth2 import service_account
from jafgen.simulation import Simulation

app = typer.Typer(add_completion=False)

project_root = Path(__file__).resolve().parents[1]
script_root = Path(__file__).resolve().parent
env_path = project_root / ".env"
default_data_dir = script_root / "data"


def load_environment() -> None:
    if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
        load_dotenv(env_path)


def get_env_values() -> tuple[str | None, str | None, str | None]:
    load_environment()
    key_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    project_id = os.getenv("DBT_RAW_PROJECT_ID") 
    dataset_id = os.getenv("DBT_RAW_DATASET_ID") 
    return key_path, project_id, dataset_id


def get_data_dir() -> Path:
    data_dir = os.getenv("DBT_DATA_DIR")
    return Path(data_dir).expanduser().resolve() if data_dir else default_data_dir


def generate_jaffle_data(years: int, prefix: str, data_dir: Path) -> None:
    print(f"🔧 Generating {years} year(s) of Jaffle Shop raw data with prefix='{prefix}'")
    data_dir = data_dir.expanduser().resolve()
    data_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        current_cwd = Path.cwd()
        try:
            os.chdir(temp_path)
            sim = Simulation(years, prefix)
            sim.run_simulation()
            sim.save_results()
        finally:
            os.chdir(current_cwd)

        generated_dir = temp_path / "jaffle-data"
        if not generated_dir.exists():
            typer.echo("jafgen did not create a `jaffle-data` folder")
            raise typer.Exit(code=1)

        for csv_path in generated_dir.glob(f"{prefix}_*.csv"):
            target_path = data_dir / csv_path.name
            if target_path.exists():
                target_path.unlink()
            shutil.move(str(csv_path), target_path)
            print(f"   wrote {target_path}")



def load_data_to_bigquery(write_disposition: str, data_dir: Path) -> None:
    key_path, project_id, dataset_id = get_env_values()
    if not key_path:
        typer.echo("Missing GOOGLE_APPLICATION_CREDENTIALS")
        raise typer.Exit(code=1)
    if not project_id:
        typer.echo("Missing DBT_RAW_PROJECT_ID")
        raise typer.Exit(code=1)
    if not dataset_id:
        typer.echo("Missing DBT_RAW_DATASET_ID")
        raise typer.Exit(code=1)

    data_dir = data_dir.expanduser().resolve()
    print(f"🔍 Loading environment from: {env_path}")
    print(f"🔍 Using data directory: {data_dir}")

    try:
        credentials = service_account.Credentials.from_service_account_file(key_path)
        client = bigquery.Client(credentials=credentials, project=project_id)
        print(f"✅ Authenticated as {credentials.service_account_email}")
    except Exception as exc:
        typer.echo(f"Authentication failed: {exc}")
        raise typer.Exit(code=1)

    dataset_ref = f"{project_id}.{dataset_id}"
    try:
        client.get_dataset(dataset_ref)
        print(f"Dataset '{dataset_id}' exists.")
    except Exception:
        print(f"Dataset '{dataset_id}' not found. Creating it...")
        client.create_dataset(bigquery.Dataset(dataset_ref))
        print(f"Dataset '{dataset_id}' created.")

    csv_files = sorted(data_dir.glob("*.csv"))
    if not csv_files:
        typer.echo(f"No CSV files found in {data_dir}")
        raise typer.Exit(code=1)

    for csv_path in csv_files:
        table_name = csv_path.stem.split("_")[-1]
        try:
            df = pd.read_csv(csv_path, dtype=str)
            print(f"Loading {csv_path.name} -> {project_id}.{dataset_id}.{table_name} ({len(df)} rows)")
            job_config = bigquery.LoadJobConfig(write_disposition=write_disposition, autodetect=True)
            table_ref = f"{project_id}.{dataset_id}.{table_name}"
            job = client.load_table_from_dataframe(df, table_ref, job_config=job_config)
            job.result()
            print(f"   Success: Loaded {len(df)} rows into `{table_ref}`")
        except Exception as exc:
            print(f"   Error loading {csv_path.name}: {exc}")


@app.command()
def main(
    write_disposition: Literal["WRITE_TRUNCATE", "WRITE_APPEND"] = typer.Option(
        "WRITE_TRUNCATE",
        help="BigQuery write disposition",
        case_sensitive=False,
    ),
    generate: bool = typer.Option(
        False,
        "--generate",
        "-g",
        help="Run jafgen data generation before loading",
    ),
    years: int = typer.Option(1, "--years", "-y", help="Number of years to generate"),
    prefix: str = typer.Option("raw", "--prefix", "-p", help="Generated CSV prefix"),
    data_dir: Path = typer.Option(get_data_dir(), "--data-dir", help="Directory with raw CSV files"),
) -> None:
    if generate:
        generate_jaffle_data(years, prefix, data_dir)
    load_data_to_bigquery(write_disposition, data_dir)


if __name__ == "__main__":
    app()
