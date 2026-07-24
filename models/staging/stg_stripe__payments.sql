    select
        id as payment_id, 
        orderid as order_id, 
        paymentmethod as payment_method, 
        status, 
        amount, 
        created, 
        _batched_at
    from {{ source('stripe', 'payment') }}
    -- from `raw-data-503215`.jaffle_shop.orders