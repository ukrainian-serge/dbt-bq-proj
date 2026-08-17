#!/usr/bin/env python3



from datetime import datetime, timedelta
from pathlib import Path
from typing import Literal

import pandas as pd
import typer
from dataclasses import asdict
from pprint import pprint

from src.config import load_config, get_bigquery_client
from src.generate import *
from src.process_dates import *
from src.loader import load_data_to_bigquery

app = typer.Typer(add_completion=False)

@app.command()
def main(
    write_disposition: Literal["WRITE_TRUNCATE", "WRITE_APPEND"] = typer.Option(
        "WRITE_TRUNCATE",
        "--write-disposition", "-w",
        help="BigQuery write disposition",
        case_sensitive=False,
        ),
    generate: bool = typer.Option(
        False,
        "--generate", "-g",
        help="Run jafgen data generation before loading",
        ),
    prefix: str = typer.Option(
        "raw", 
        "--prefix", "-p", 
        help="Generated CSV prefix"
        ),
    data_dir: Path = typer.Option(
        None, 
        "--data-dir", "-d", 
        help="Directory with raw CSV files"
        ),
    date_from: datetime = typer.Option(
        lambda: (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d"),
        "--daterange-from", "-f",
        help="Date range start (YYYY-MM-DD format). Defaults to 7 days ago.",
        callback=validate_and_parse,
    ),
    date_to: datetime = typer.Option(
        lambda: datetime.now().strftime("%Y-%m-%d"),
        "--daterange-to", "-t",
        help="Date range end (YYYY-MM-DD format). Defaults to today.",
        callback=validate_and_parse,
    ),
) -> None:
<<<<<<< HEAD
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
=======
>>>>>>> feature/gen-load

    # insptect a valid date range first
    validate_date_range(date_from, date_to)

    cfg = load_config()

    cfg.write_disposition = write_disposition
    cfg.generate = generate
    cfg.prefix = prefix
    cfg.data_dir = data_dir or (Path(__file__).parents[1] / "jaffle_raw_data")
    cfg.date_from = date_from
    cfg.date_to = date_to

    calculate_years_from_range(cfg)
    get_date_range_series(cfg)
    generate_jaffle_data(cfg)
    process_generated_data(cfg)
    get_bigquery_client(cfg)
    load_data_to_bigquery(cfg)

    # print(cfg)

if __name__ == "__main__":
    app()
