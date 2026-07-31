
with customers as (

    select * FROM {{ ref('stg_jaffle_shop__customers') }}

),

orders as (

    select * FROM {{ ref('stg_jaffle_shop__orders') }}
    
),

customer_orders as (

    select
        customer_id,

        min(ordered_at) as first_order_date,
        max(ordered_at) as most_recent_order_date,
        count(order_id) as number_of_orders,
        sum(order_total) as lifetime_value

    from orders

    group by 1

),


-- final as (

--     select
--         A.customer_id,
--         A.first_name,
--         A.last_name,
--         B.first_order_date,
--         B.most_recent_order_date,
--         coalesce(B.number_of_orders, 0) as number_of_orders,
--         coalesce(B.lifetime_value, 0) as lifetime_value

--     from customers as A

--     left join customer_orders AS B using (customer_id)

-- )

select * from final
