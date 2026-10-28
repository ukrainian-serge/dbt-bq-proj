{{
  config(
    materialized = 'table',
    full_refresh=true,
    enabled=true
    )
}}


{# Legacy fact table for customer orders
    NEED CASTING TO TEST #}

WITH paid_orders as (

    select Orders.id as order_id,
        Orders.id    as customer_id,
        CAST(Orders.ordered_at AS DATETIME) AS order_placed_at,
        p.total_amount_paid,
        p.payment_finalized_date,
        SPLIT(c.name, ' ')[SAFE_OFFSET(0)] AS customer_first_name,
        SPLIT(c.name, ' ')[SAFE_OFFSET(1)] AS customer_last_name
    FROM {{ source('jaffle_shop', 'orders') }} as Orders
    INNER join (
        select 
            id, 
            max(CAST(ordered_at AS DATETIME)) as payment_finalized_date, 
            sum(CAST(order_total AS FLOAT64)) as total_amount_paid
        from {{ source('jaffle_shop', 'orders') }}
        WHERE CAST(order_total AS FLOAT64) > 0
        group by 1

        ) p ON orders.id = p.id
    left join {{ source('jaffle_shop', 'customers') }} C on orders.customer = C.id 

),

customer_orders as (
        select Orders.id as customer_id
        , min(CAST(ordered_at AS DATETIME)) as first_order_date
        , max(CAST(ordered_at AS DATETIME)) as most_recent_order_date
        , count(Orders.id) AS number_of_orders
    from {{ source('jaffle_shop', 'orders') }} as Orders
    group by 1
    )

select
    CAST(p.order_id AS STRING) as order_id,
    CAST(p.customer_id AS STRING) as customer_id,
    CAST(p.order_placed_at AS DATETIME) as order_placed_at,
    CAST(p.total_amount_paid AS FLOAT64) as total_amount_paid,
    CAST(p.payment_finalized_date AS DATETIME) as payment_finalized_date,
    CAST(p.customer_first_name AS STRING) as customer_first_name,
    CAST(p.customer_last_name AS STRING) as customer_last_name,
    CAST(ROW_NUMBER() OVER (ORDER BY p.order_id) AS INT) as transaction_seq,
    CAST(ROW_NUMBER() OVER (PARTITION BY p.customer_id ORDER BY p.order_id) AS INT) as customer_sales_seq,
    CAST(CASE WHEN c.first_order_date = p.order_placed_at
        THEN 'new'
        ELSE 'return' END AS STRING) as nvsr,
    CAST(SUM(p.total_amount_paid) OVER (
        PARTITION BY p.customer_id 
        ORDER BY p.order_placed_at 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS FLOAT64) AS customer_lifetime_value,
    CAST(c.first_order_date AS DATETIME) as fdos
    FROM paid_orders p
    left join customer_orders as c 
        USING (customer_id)
    ORDER BY order_id