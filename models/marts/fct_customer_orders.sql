{{ config(
    materialized = 'incremental',
    incremental_strategy = 'microbatch',
    event_time = 'order_placed_at',
    begin = '2019-01-01',
    batch_size = 'day',
    lookback = 2,
    full_refresh = false,
    partition_by ={ "field": "order_placed_at",
    "data_type": "datetime",
    "granularity": "day" }
) }}

WITH int_customer_orders AS (

    SELECT
        *
    FROM
        {{ ref('int_customer_orders') }}
),
customer_name_mapper AS (
    SELECT
        *
    FROM
        {{ ref('stg_jaffle_shop__customers') }}
),
FINAL AS (
    SELECT
        orders.order_id,
        orders.customer_id,
        orders.ordered_at AS order_placed_at,
        orders.order_total_amount_paid AS total_amount_paid,
        orders.order_finalized_date AS payment_finalized_date,
        customer_mapper.first_name AS customer_first_name,
        customer_mapper.last_name AS customer_last_name,
        orders.transaction_seq,
        orders.customer_sales_seq,
        orders.customer_lifetime_value,
        orders.customer_first_order_date AS fdos,
        CASE
            WHEN orders.ordered_at = orders.customer_first_order_date THEN 'new'
            ELSE 'return'
        END AS nvsr
    FROM
        int_customer_orders AS orders
        LEFT JOIN customer_name_mapper AS customer_mapper
        ON orders.customer_id = customer_mapper.customer_id
)
SELECT
    *
FROM
    FINAL
