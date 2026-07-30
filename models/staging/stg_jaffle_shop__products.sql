WITH stg AS (
    SELECT 
        sku,
        name,
        type,
        CAST(price AS FLOAT64) as price,
        description
    FROM {{ source('jaffle_shop', 'products') }}
)



, final AS (
    SELECT 
        sku,
        name,
        type,
        SAFE_DIVIDE(price, 100) as price,
        description
    FROM stg
)

SELECT * FROM final