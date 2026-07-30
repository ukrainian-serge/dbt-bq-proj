WITH stg AS (
    SELECT
        id,
        order_id,
        sku
    FROM {{ source('jaffle_shop', 'items') }}
)

, final AS (
    SELECT
        id as item_id,
        order_id,
        sku
    FROM stg
)

SELECT * FROM final