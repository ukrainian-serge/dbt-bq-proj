import tempfile
import os
import shutil
from pathlib import Path
import typer
import pandas as pd

from jafgen.simulation import Simulation
from src.config import *

def generate_jaffle_data(cfg: Config) -> None:
    """Runs jafgen simulation and saves generated raw CSVs to data_dir."""

    if cfg.generate:

        cfg.data_dir.mkdir(parents=True, exist_ok=True)

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            current_cwd = Path.cwd()
            try:
                os.chdir(temp_path)
                sim = Simulation(cfg.calculated_years, cfg.prefix)
                sim.run_simulation()
                sim.save_results()
            finally:
                os.chdir(current_cwd)

            generated_dir = temp_path / "jaffle-data"
            if not generated_dir.exists():
                typer.echo("jafgen did not create a `jaffle-data` folder", err=True)
                raise typer.Exit(code=1)

            for csv_path in generated_dir.glob(f"{cfg.prefix}_*.csv"):
                target_path = cfg.data_dir / csv_path.name
                if target_path.exists():
                    target_path.unlink()
                shutil.move(str(csv_path), target_path)
                print(f"   wrote {target_path}")
    else:
        typer.echo("No --generate/-g flag passed. Skipping jafgen.Simulation", err=False)


def map_and_filter_dates(df_src, df_dst) -> pd.DataFrame:
    """
    This does the mapping and filtering on the jaffle date range data.
    Currently, orders.csv and tweets.csv are the fact data for this slice.
    """

    col = [col for col in df_src.columns 
            if any(kw in col.lower() for kw in ['date', 'at', 'time', 'timestamp'])][0]
    
    col_date = f'{col}_date'
    col_time = f'{col}_time'

    df_src[col_date] = df_src[col].str[:10]

    df_src[col_time] = df_src[col].str[10:]

    # create src from csv files. sort, reset index. index needed as key for join
    s_src = pd.Series(
        df_src[col_date].unique(),
        name='src'
        ).sort_values(ascending=False).reset_index(drop=True)
    
    # inner join to filter jaffle data down to s_dst len(days) 
    join_df = pd.concat([df_dst, s_src], 
        axis=1, join="inner"
        )

    # creates mapper dict for filter and mapping the yyyy-mm-dd 
    date_map = join_df.set_index('src')['dst'].to_dict() 

    # apply the above filtering
    df_filtered = df_src[df_src[col_date].isin(join_df['src'])].copy()

    # get new filteres series with mapped col_date
    mapped_dst_dates = df_filtered[col_date].map(date_map)

    # dst Date + src Time concat happens here. Produces datetime-like string
    df_filtered[col] = mapped_dst_dates + df_filtered[col_time]

    # drop helper columns
    df_filtered.drop(columns=[col_date, col_time], inplace=True)

    return df_filtered


def alter_orders(csv_path: Path, cfg: Config) -> None:
    """
    Dates mapped and df sliced down to cfg.date_from and cfg.date_to. 
    Sets unique order and customer id's to slice down items and customers tables
    """
    df_src = pd.read_csv(csv_path)
    df_dst = map_and_filter_dates(df_src, cfg.s_dst)

    # orders is the primary table where we use to filter the rest down, on order_id, custer_id
    cfg.order_unique_id = df_dst.id.unique()
    cfg.order_unique_cust = df_dst.customer.unique()

    df_dst.to_csv(csv_path, index=False)


def alter_tweets(csv_path: Path, cfg: Config) -> None:
    """
    Dates mapped and df sliced down to cfg.date_from and cfg.date_to
    """
    df_src = pd.read_csv(csv_path)
    df_dst = map_and_filter_dates(df_src, cfg.s_dst)

    df_dst.to_csv(csv_path, index=False)


def alter_items(csv_path: Path, cfg: Config) -> None:
    """
    Slices data down using cfg.order_unique_id, which was set by alter_orders()
    """
    df_src = pd.read_csv(csv_path)
    df_dst = df_src[df_src['order_id'].isin(cfg.order_unique_id)]

    df_dst.to_csv(csv_path, index=False)


def alter_customers(csv_path: Path, cfg: Config) -> None:
    """
    Slices data down using cfg.order_unique_cust, which was set by alter_orders()
    """
    df_src = pd.read_csv(csv_path)
    df_dst = df_src[df_src['id'].isin(cfg.order_unique_cust)]

    df_dst.to_csv(csv_path, index=False)


def process_generated_data(cfg: Config) -> None:
    """
    Loops generated jaffle data.
    Filter jaffle data based on daterange provided. s_dst: series created by get_date_range_series()
    Map jaffle date col by replacing the yyyy-mm-dd in (yyyy-mm-dd)THH:MM:SSSS, with the s_dst
    """

    data_dict = {}

    for csv_path in cfg.data_dir.glob(f"{cfg.prefix}_*.csv"):
        key = csv_path.stem.split('_')[-1]
        value = csv_path
        data_dict[key] = value


    alter_orders(data_dict['orders'], cfg)
    alter_tweets(data_dict['tweets'], cfg)
    alter_items(data_dict['items'], cfg)
    alter_customers(data_dict['customers'], cfg)
        

        
            



