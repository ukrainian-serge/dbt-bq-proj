    select
        id as customer_id,
        first_name,
        last_name
    from {{ source('jaffle_shop', 'customers') }}
    -- from `raw-data-503215`.jaffle_shop.customers