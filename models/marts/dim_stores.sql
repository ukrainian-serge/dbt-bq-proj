
with stores as (

    select * FROM {{ ref('stg_jaffle_shop__stores') }}

),

orders as (

    select * FROM {{ ref('stg_jaffle_shop__orders') }}
    
),


store_orders as (

    select
        store_id,

        min(ordered_at) as first_order_date,
        max(ordered_at) as most_recent_order_date,
        count(order_id) as number_of_orders,
        sum(order_total) as lifetime_value

    from orders

    group by 1

)

, final as (

    select
        A.store_id,
        A.name,
        B.first_order_date,
        B.most_recent_order_date,
        coalesce(B.number_of_orders, 0) as number_of_orders,
        coalesce(B.lifetime_value, 0) as lifetime_value

    from stores as A

    left join store_orders AS B using (store_id)

)

select * from final
