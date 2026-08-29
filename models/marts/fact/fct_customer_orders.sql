{#  
this is now placed in the yml schema 
{{
    config(
        
        materialized="incremental",
        incremental_strategy="microbatch",
        event_time="order_placed_at",
        begin="2026-08-01",
        batch_size="day",
        unique_key="order_id",
        lookback=2,

        partition_by={
            "field": "order_placed_at",
            "data_type": "datetime",
            "granularity": "day",
        },
    )
}} #}

with
    int_customer_orders as (select * from {{ ref("int_customer_orders") }}),
    customer_name_mapper as (select * from {{ ref("stg_jaffle_shop__customers") }}),
    final as (
        select
            orders.order_id,
            {# cast(NULL as string) as order_id, #}
            orders.customer_id,
            orders.ordered_at as order_placed_at,
            orders.order_total_amount_paid as total_amount_paid,
            orders.order_finalized_date as payment_finalized_date,
            customer_mapper.first_name as customer_first_name,
            customer_mapper.last_name as customer_last_name,
            orders.transaction_seq,

            orders.customer_sales_seq,
            orders.customer_lifetime_value,
            orders.customer_first_order_date as fdos,
            case
                when orders.ordered_at = orders.customer_first_order_date
                then 'new'
                else 'return'
            end as nvsr
        from int_customer_orders as orders
        left join
            customer_name_mapper as customer_mapper
            on orders.customer_id = customer_mapper.customer_id
    )
select *
from final