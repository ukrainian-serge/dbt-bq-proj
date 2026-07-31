WITH source AS (
    SELECT * FROM {{ source('jaffle_shop', 'products') }}
)



, final AS (
    SELECT 
        sku,
        name as product_name,
        type as product_type,
        SAFE_DIVIDE(CAST(price AS FLOAT64), 100) as price,
        description
    FROM source
)

SELECT * FROM final