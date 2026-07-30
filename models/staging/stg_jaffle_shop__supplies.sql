WITH stg AS (
    SELECT
        id as supply_id,
        name,
        CAST(cost AS FLOAT64) as cost,
        CAST(perishable AS BOOLEAN) as perishable,
        sku
    FROM {{source('jaffle_shop', 'supplies')}}
)



, final AS (
    SELECT
        supply_id,
        name,
        SAFE_DIVIDE(cost, 100) as cost,
        perishable,
        sku
    FROM stg
)

SELECT * FROM final