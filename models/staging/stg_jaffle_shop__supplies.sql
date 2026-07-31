WITH source AS (
    SELECT * FROM {{source('jaffle_shop', 'supplies')}}
)

, final AS (
    SELECT
        id as supply_id,
        name as supplies_name,
        SAFE_DIVIDE(CAST(cost AS FLOAT64), 100) as cost,
        CAST(perishable AS BOOLEAN) as perishable,
        sku
    FROM source
)

SELECT * FROM final