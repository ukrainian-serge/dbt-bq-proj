WITH stg AS (
    select
        id,
        customer,
        CAST(ordered_at AS DATE) as ordered_at,
        store_id,
        CAST(subtotal AS integer) as subtotal,
        CAST(tax_paid AS integer) as tax_paid,
        CAST(order_total AS integer) as order_total
    from {{ source('jaffle_shop', 'orders') }}
)

, final AS (
    select
        id as order_id,
        customer as customer_id,
        ordered_at,
        store_id,
        SAFE_DIVIDE(subtotal, 100) as subtotal,
        SAFE_DIVIDE(tax_paid, 100) as tax_paid,
        SAFE_DIVIDE(order_total, 100) as order_total
    from stg
)

SELECT * FROM final