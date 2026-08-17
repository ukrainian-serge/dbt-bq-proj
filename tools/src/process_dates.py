import typer
import pandas as pd
from datetime import datetime, date
import pandas as pd
from src.config import Config



def validate_and_parse(value: str | datetime) -> datetime:
    """Callback to validate and parse YYYY-MM-DD string into a datetime object."""
    if isinstance(value, datetime):
        # print(type(value))
        return value
    if isinstance(value, date):
        print(type(value))
        return datetime.combine(value, datetime.min.time())
    try:
        return datetime.strptime(value, "%Y-%m-%d")
    except ValueError:
        raise typer.BadParameter(f"'{value}' is not a valid date. Format must be YYYY-MM-DD.")


def validate_date_range(date_from: date, date_to: date) -> None:
    """Helper to ensure start date is before or equal to end date."""
    if date_from > date_to:
        raise typer.BadParameter(
            f"Invalid date range: '--date-from' ({date_from.strftime('%Y-%m-%d')}) "
            f"cannot be after '--date-to' ({date_to.strftime('%Y-%m-%d')})."
        )


def calculate_years_from_range(cfg: Config) -> None:
    """Calculate years needed based on date range."""
    days = (cfg.date_to - cfg.date_from).days + 1
    years = (days + 364) // 365
    cfg.calculated_years = max(1, years)



def get_date_range_series(cfg: Config) -> None:
    """
    Generates a daily date Series where:
    Index 0 = latest date (date_to)
    Index N = earliest date (date_from)

    This will be used for INNER JOINING on the actual csv data(orders, tweets) and mapping proper yyyy-mm-dd
    """
    
    # 1. Generate dates ascending
    dates = pd.date_range(start=cfg.date_from, end=cfg.date_to, freq="D").astype('str')

    cfg.s_dst = pd.Series(dates, name='dst').sort_values(ascending=False).reset_index(drop=True) 



