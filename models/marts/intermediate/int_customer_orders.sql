{{ config(
    materialized='table',
    event_time='ordered_at',
    full_refresh=false,
    partition_by={
      "field": "ordered_at",
      "data_type": "datetime",
      "granularity": "day"
    },
    cluster_by=["customer_id"]


) }}


WITH orders AS (
    SELECT *
    FROM {{ ref('stg_jaffle_shop__orders') }}
)

, joined AS (
    SELECT
        a.order_id
        , a.customer_id
        , a.ordered_at
        , sum(order_total)
            OVER (PARTITION BY order_id)
            AS order_total_amount_paid
        , max(a.ordered_at)
            OVER (PARTITION BY a.order_id)
            AS order_finalized_date
        , max(a.ordered_at)
            OVER (PARTITION BY a.customer_id)
            AS customer_most_recent_order_date
        , count(*)
            OVER (PARTITION BY a.customer_id)
            AS customer_lifetime_order_count
        , row_number() OVER (
            ORDER BY order_id
        ) AS transaction_seq
        -- Order sequence & running CLV
        , row_number() OVER (
            PARTITION BY customer_id
            ORDER BY
                a.ordered_at
                , order_id
        ) AS customer_sales_seq
        -- nvsr goes here
        , sum(a.order_total) OVER (
            PARTITION BY customer_id
            ORDER BY
                a.ordered_at
                , order_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS customer_lifetime_value
        , min(a.ordered_at)
            OVER (PARTITION BY a.customer_id)
            AS customer_first_order_date
    FROM orders AS a
    WHERE order_total > 0
)

, final AS (
    SELECT
        *
        , {{ function('divide_udf') }}(
            customer_lifetime_value
            , customer_lifetime_order_count
        ) AS customer_avg_non_returned_order_value
    FROM joined
)

SELECT *
FROM final
