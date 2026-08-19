WITH source AS (
    SELECT * FROM {{ source('jaffle_shop', 'supplies') }}
)

, final AS (
    SELECT
        id AS supply_id
        , name AS supplies_name
        , CAST(perishable AS BOOLEAN) AS perishable
        , sku
        , SAFE_DIVIDE(CAST(cost AS FLOAT64), 100) AS cost
    FROM source
)

SELECT * FROM final
