WITH source AS (
    SELECT
        *
    FROM
        {{ source(
            'jaffle_shop',
            'customers'
        ) }}
),
trimmed AS (
    SELECT
        id AS customer_id,
        TRIM(NAME) AS first_and_last_name
    FROM
        source
),
FINAL AS (
    SELECT
        customer_id,
        SPLIT(
            first_and_last_name,
            ' '
        ) [SAFE_OFFSET(0)] AS first_name,
        SPLIT(
            first_and_last_name,
            ' '
        ) [SAFE_OFFSET(1)] AS last_name
    FROM
        trimmed
)
SELECT
    *
FROM
    FINAL
