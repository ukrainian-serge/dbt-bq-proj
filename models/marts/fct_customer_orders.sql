with 

 int_customer_orders AS (
    SELECT * FROM {{ ref('int_customer_orders') }}
)

, customer_name_mapper AS (
    select * from {{ ref('stg_jaffle_shop__customers')}}
)

, audit_conflict as (
    -- SELECTING HERE JUST TO TEST BUILD AND LINEAGE
    select * from {{ ref('fct_customer_orders_audit_conflict_summary')}}
)

, final as (
    select 
        orders.order_id,
        orders.customer_id,
        orders.ordered_at as order_placed_at,
        orders.order_total_amount_paid as total_amount_paid,
        orders.order_finalized_date as payment_finalized_date,
        customer_mapper.first_name as customer_first_name,
        customer_mapper.last_name as customer_last_name,
        orders.transaction_seq as transaction_seq,
        orders.customer_sales_seq as customer_sales_seq,
        case when ordered_at = customer_first_order_date then 'new'
                else 'return'
                end as nvsr,
        orders.customer_lifetime_value as customer_lifetime_value,
        orders.customer_first_order_date as fdos

    from int_customer_orders as orders
    left join customer_name_mapper as customer_mapper using(customer_id)
)

select * from final