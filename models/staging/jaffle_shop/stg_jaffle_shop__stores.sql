WITH stg AS (
    SELECT 
        id as store_id,
        name,
        CAST(opened_at AS DATETIME) as opened_at,
        CAST(tax_rate AS FLOAT64) as tax_rate
    FROM {{ source('jaffle_shop', 'stores') }}
)


, final AS (
    SELECT 
        store_id,
        name,
        opened_at,
        tax_rate
    FROM stg
)

SELECT * FROM final