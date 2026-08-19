WITH source AS (
    SELECT * FROM {{ source('jaffle_shop', 'products') }}
)


, final AS (
    SELECT
        sku
        , name AS product_name
        , type AS product_type
        , description
        , SAFE_DIVIDE(CAST(price AS FLOAT64), 100) AS price
    FROM source
)

SELECT * FROM final
