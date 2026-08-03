-- CREATE OR REPLACE TABLE `dbt-prod-503215.jaffle_shop.fct_customer_orders_legacy` AS
CREATE OR REPLACE TABLE `dbt-dev-503215.dbt_skamilchu.fct_customer_orders_legacy` AS

WITH paid_orders as (

    select Orders.order_id as order_id,
        Orders.customer_id    as customer_id,
        Orders.ordered_at AS order_placed_at,
        p.total_amount_paid,
        p.payment_finalized_date,
        C.first_name    as customer_first_name,
        C.last_name as customer_last_name
    FROM `dbt-dev-503215.dbt_skamilchu.stg_jaffle_shop__orders` as Orders
    INNER join (
        select 
            order_id, 
            max(ordered_at) as payment_finalized_date, 
            sum(order_total) as total_amount_paid
        from `dbt-dev-503215.dbt_skamilchu.stg_jaffle_shop__orders`
        WHERE order_total > 0
        group by 1

        ) p ON orders.order_id = p.order_id
    left join `dbt-dev-503215.dbt_skamilchu.stg_jaffle_shop__customers` C on orders.customer_id = C.customer_id 

),

customer_orders as (
        select Orders.customer_id as customer_id
        , min(ordered_at) as first_order_date
        , max(ordered_at) as most_recent_order_date
        , count(Orders.order_id) AS number_of_orders
    from `dbt-dev-503215.dbt_skamilchu.stg_jaffle_shop__orders` as Orders
    group by 1
    )

select
    p.*,
    ROW_NUMBER() OVER (ORDER BY p.order_id) as transaction_seq,
    ROW_NUMBER() OVER (PARTITION BY p.customer_id ORDER BY p.order_id) as customer_sales_seq,
    CASE WHEN c.first_order_date = p.order_placed_at
    THEN 'new'
    ELSE 'return' END as nvsr,

    -- x.customer_lifetime_value,

    SUM(p.total_amount_paid) OVER (
        PARTITION BY p.customer_id 
        ORDER BY p.order_placed_at 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS customer_lifetime_value,

    c.first_order_date as fdos
    FROM paid_orders p
    left join customer_orders as c 
        USING (customer_id)
    -- LEFT JOIN 
    -- (
    --     select
    --         p.customer_id,
    --         sum(total_amount_paid) as customer_lifetime_value
    --     from paid_orders p
    --     group by 1
    -- ) x on x.customer_id = p.customer_id
    ORDER BY order_id

;