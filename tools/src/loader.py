import typer
from pathlib import Path
import pandas as pd
import pandas as pd

from google.cloud.bigquery import LoadJobConfig, Client
from src.config import Config

def string_col_dtype_inspection(df: pd.DataFrame, table_name):
    non_string_cols = [
        col for col in df.columns 
        if not pd.api.types.is_object_dtype(df[col]) and not pd.api.types.is_string_dtype(df[col])
    ]

    if non_string_cols:
        invalid_details = {col: str(df[col].dtype) for col in non_string_cols}
        raise TypeError(
            f"Table '{table_name}' contains non-string columns: {invalid_details}. "
            f"All columns must be strings/objects before loading."
        )

def load_data_to_bigquery(cfg: Config) -> None:
    
    csv_files = sorted(cfg.data_dir.glob("*.csv"))

    if not csv_files:
        typer.echo(f"No CSV files found in {cfg.data_dir}")
        raise typer.Exit(code=1)

    for csv_path in csv_files:
        table_name = csv_path.stem.split("_")[-1]
        try:
            ## RAW loaded tables must be strings
            df = pd.read_csv(csv_path, dtype=str)

            # added exception throw if cols not string/object dtyp
            string_col_dtype_inspection(df, table_name)

            job_config = LoadJobConfig(
                write_disposition=cfg.write_disposition, 
                autodetect=True
                )
            table_ref = f"{cfg.dataset_ref}.{table_name}"

            assert cfg.client is not None, "BigQuery client must be initialized before loading data."

            job = cfg.client.load_table_from_dataframe(
                df, 
                table_ref, 
                job_config=job_config
                )
            job.result()
            print(f"   Success: Loaded {len(df)} rows into `{table_ref}`")
        except Exception as exc:
            print(f"   Error loading {csv_path.name}: {exc}")
