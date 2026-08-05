def model(dbt, session):
    dbt.config(
        materialized="table",
        submission_method="bigframes",
        packages=["holidays"]
    )

    import holidays          # now runs after packages are installed
    import pandas as pd

    us_holidays = holidays.US()
    df = dbt.ref("dates_spine").to_pandas()
    df["is_holiday"] = df["date_day"].apply(lambda x: x in us_holidays)
    return df