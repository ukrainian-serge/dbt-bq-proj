{{
    config(
        materialized="table",
        event_time="ordered_at",
        full_refresh=false,
        partition_by={
            "field": "ordered_at",
            "data_type": "datetime",
            "granularity": "day",
        },
        cluster_by=["customer_id"],
    )
}}


with
    orders as (select * from {{ ref("stg_jaffle_shop__orders") }}),
    joined as (
        select
            a.order_id,
            a.customer_id,
            a.ordered_at,
            sum(order_total) over (partition by order_id) as order_total_amount_paid,
            max(a.ordered_at) over (partition by a.order_id) as order_finalized_date,
            max(a.ordered_at) over (
                partition by a.customer_id
            ) as customer_most_recent_order_date,
            count(*) over (partition by a.customer_id) as customer_lifetime_order_count,
            row_number() over (order by order_id) as transaction_seq,
            -- Order sequence & running CLV
            row_number() over (
                partition by customer_id order by a.ordered_at, order_id
            ) as customer_sales_seq,
            -- nvsr goes here
            sum(a.order_total) over (
                partition by customer_id
                order by a.ordered_at, order_id
                rows between unbounded preceding and current row
            ) as customer_lifetime_value,
            min(a.ordered_at) over (
                partition by a.customer_id
            ) as customer_first_order_date
        from orders as a
        where order_total > 0
    ),
    final as (
        select
            *,
            {{ function("divide_udf") }} (
                customer_lifetime_value, customer_lifetime_order_count
            ) as customer_avg_non_returned_order_value
        from joined
    )

select *
from final