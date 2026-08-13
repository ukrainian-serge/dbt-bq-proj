#!/usr/bin/env python3

import os
import shutil
import tempfile
from datetime import datetime, timedelta
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
default_data_dir = script_root / "data"     ### defaults to this if .end does not have a folder name


def load_environment() -> None:
    if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
        load_dotenv(env_path)


def get_env_values() -> tuple[str | None, str | None, str | None]:
    load_environment()
    key_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    project_id = os.getenv("DBT_RAW_PROJECT_ID") 
    dataset_id = os.getenv("DBT_RAW_DATASET_ID") 
    return key_path, project_id, dataset_id

def parse_date(date_str: str) -> datetime:
    """Parse date string in YYYY-MM-DD format."""
    try:
        return datetime.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        raise typer.BadParameter(f"Date must be in YYYY-MM-DD format, got: {date_str}")


def calculate_years_from_range(date_from: datetime, date_to: datetime) -> int:
    """Calculate years needed based on date range."""
    days = (date_to - date_from).days + 1  # Include both endpoints
    years = (days + 364) // 365  # Ceiling division
    return years


def filter_dates_to_range(df: pd.DataFrame, date_from: datetime, date_to: datetime) -> pd.DataFrame:
    """
    Filter rows to only include those with dates within the range.
    Creates a date spine and filters any datetime column to it.
    """
    breakpoint()
    datetime_cols = df.select_dtypes(include=['datetime64']).columns.tolist()
    
    if not datetime_cols:
        # Try parsing string columns that look like dates
        for col in df.columns:
            if df[col].dtype == 'object':
                try:
                    parsed = pd.to_datetime(df[col], errors='coerce')
                    if parsed.notna().sum() > len(df) * 0.8:  # 80%+ valid dates
                        df[col] = parsed
                        datetime_cols.append(col)
                except:
                    pass
    
    if not datetime_cols:
        return df
    
    df_copy = df.copy()
    
    # Convert all datetime columns to datetime type
    for col in datetime_cols:
        df_copy[col] = pd.to_datetime(df_copy[col])
    
    # Create mask: keep rows where ANY datetime column falls within range
    mask = pd.Series([False] * len(df_copy), index=df_copy.index)
    
    for col in datetime_cols:
        col_mask = (df_copy[col] >= date_from) & (df_copy[col] <= date_to)
        mask |= col_mask
    
    return df_copy[mask]


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





def load_data_to_bigquery(write_disposition: str, data_dir: Path, date_from: datetime | None = None, date_to: datetime | None = None) -> None:
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
            df = pd.read_csv(csv_path)
            original_count = len(df)
            
            # Apply date range filter if specified
            if date_from and date_to:
                df = filter_dates_to_range(df, date_from, date_to)
                filtered_count = len(df)
                print(f"Loading {csv_path.name} -> {project_id}.{dataset_id}.{table_name} ({filtered_count} of {original_count} rows, filtered to {date_from.date()} - {date_to.date()})")
            else:
                print(f"Loading {csv_path.name} -> {project_id}.{dataset_id}.{table_name} ({original_count} rows)")
            
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
    years: int = typer.Option(None, "--years", "-y", help="Number of years to generate (auto-calculated from date range if not specified)"),
    prefix: str = typer.Option("raw", "--prefix", "-p", help="Generated CSV prefix"),
    data_dir: Path = typer.Option(get_data_dir(), "--data-dir", "-d", help="Directory with raw CSV files"),
    daterange_from: str | None = typer.Option(
        None,
        "--daterange-from",
        "-f",
        help="Date range start (YYYY-MM-DD format)",
    ),
    daterange_to: str | None = typer.Option(
        None,
        "--daterange-to",
        "-t",
        help="Date range end (YYYY-MM-DD format)",
    ),
) -> None:
    date_from = parse_date(daterange_from) if daterange_from else None
    date_to = parse_date(daterange_to) if daterange_to else None
    
    # Determine years to generate
    if generate:
        if date_from and date_to:
            calculated_years = calculate_years_from_range(date_from, date_to)
            print(f"📅 Date range {date_from.date()} - {date_to.date()} ({(date_to - date_from).days + 1} days) requires {calculated_years} year(s)")
            generate_jaffle_data(calculated_years, prefix, data_dir)
        elif years is not None:
            generate_jaffle_data(years, prefix, data_dir)
        else:
            generate_jaffle_data(1, prefix, data_dir)
    # elif:
        
        
    
    load_data_to_bigquery(write_disposition, data_dir, date_from=date_from, date_to=date_to)


if __name__ == "__main__":
    app()

    # print("=" * 50)
    # print("🚀 RUNNING STEP-BY-STEP PIPELINE TEST")
    # print("=" * 50)

    # # ----------------------------------------------------
    # # STEP 1: Test Environment Configuration
    # # ----------------------------------------------------
    # print("\n--- [Step 1] Loading Environment & Directories ---")
    # key_path, project_id, dataset_id = get_env_values()
    # data_dir = get_data_dir()

    # print(f"Key Path:   {key_path}")
    # print(f"Project ID: {project_id}")
    # print(f"Dataset ID: {dataset_id}")
    # print(f"Data Dir:   {data_dir}")

    # # ----------------------------------------------------
    # # STEP 2: Test Date Parsing & Math
    # # ----------------------------------------------------
    # print("\n--- [Step 2] Testing Date Parsing & Math ---")
    # # raw_from = "2023-01-01"
    # # raw_to = "2024-06-30"\
    # raw_from = '2026-01-01'
    # raw_to = '2026-08-01'

    # date_from = parse_date(raw_from)
    # date_to = parse_date(raw_to)
    # calculated_years = calculate_years_from_range(date_from, date_to)

    # print(f"Parsed Start: {date_from} (type: {type(date_from)})")
    # print(f"Parsed End:   {date_to} (type: {type(date_to)})")
    # print(f"Calculated Years Needed: {calculated_years}")

    # # ----------------------------------------------------
    # # STEP 3: Test Data Generation (`jafgen`)
    # # ----------------------------------------------------
    # print("\n--- [Step 3] Testing Data Generation ---")
    # # Generates raw data using the output from Step 2
    # generate_jaffle_data(years=calculated_years, prefix="raw", data_dir=data_dir)

    # generated_csvs = list(data_dir.glob("raw_*.csv"))
    # print(f"Generated {len(generated_csvs)} CSV files in {data_dir}:")
    # for csv in generated_csvs:
    #     print(f"  - {csv.name}")

    # # ----------------------------------------------------
    # # STEP 4: Test DataFrame Date Filtering (In-Memory)
    # # ----------------------------------------------------
    # print("\n--- [Step 4] Testing DataFrame Date Filtering ---")
    # if generated_csvs:
    #     sample_csv = generated_csvs[0]
    #     df_raw = pd.read_csv(sample_csv)

    #     print(f"Testing filter on `{sample_csv.name}`:")
    #     print(f"  Row count BEFORE filter: {len(df_raw)}")

    #     # Pass real DataFrame and real datetimes into filter
    #     df_filtered = filter_dates_to_range(df_raw, date_from, date_to)

    #     print(f"  Row count AFTER filter:  {len(df_filtered)}")
    #     print("\nFiltered DataFrame Sample:")
    #     print(df_filtered.head(2))

    # # ----------------------------------------------------
    # # STEP 5: Test Full BigQuery Upload Execution
    # # ----------------------------------------------------
    # print("\n--- [Step 5] Testing BigQuery Load Execution ---")
    # load_data_to_bigquery(
    #     write_disposition="WRITE_TRUNCATE",
    #     data_dir=data_dir,
    #     date_from=date_from,
    #     date_to=date_to,
    # )

    # print("\n✅ All step-by-step pipeline stages completed!")
