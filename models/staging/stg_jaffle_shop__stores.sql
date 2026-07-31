WITH source AS (
    SELECT * FROM {{ source('jaffle_shop', 'stores') }}
)


, final AS (
    SELECT 
        id as store_id,
        name as store_name,
        CAST(opened_at AS DATETIME) as opened_at,
        CAST(tax_rate AS FLOAT64) as tax_rate
    FROM source
)

SELECT * FROM final