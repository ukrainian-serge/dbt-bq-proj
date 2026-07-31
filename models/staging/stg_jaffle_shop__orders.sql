with source as (

    select * from {{ source('jaffle_shop', 'orders') }}

),

renamed as (

    select
        -- Primary & foreign keys
        id as order_id,
        customer as customer_id,
        store_id,

        -- Timestamps
        cast(ordered_at as datetime) as ordered_at,

        -- Monetary amounts (cast to int, then convert cents -> dollars)
        safe_divide(cast(subtotal as int64), 100) as subtotal,
        safe_divide(cast(tax_paid as int64), 100) as tax_paid,
        safe_divide(cast(order_total as int64), 100) as order_total

    from source

)

select * from renamed