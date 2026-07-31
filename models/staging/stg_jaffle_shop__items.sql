WITH source AS (
    SELECT * FROM {{ source('jaffle_shop', 'items') }}
)

, final AS (
    SELECT
        id as item_id,
        order_id,
        sku
    FROM source
)

SELECT * FROM final