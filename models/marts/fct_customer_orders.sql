with orders_enriched as (
    select
        o.order_id,
        o.customer_id,
        o.ordered_at as order_placed_at,
        o.order_total as total_amount_paid,
        c.first_name as customer_first_name,
        c.last_name as customer_last_name,

        -- Aggregations replaced with lightweight window functions
        min(o.ordered_at) over (partition by o.customer_id) as cust_first_order_date,
        max(o.ordered_at) over (partition by o.customer_id) as cust_most_recent_order_date,
        count(o.order_id) over (partition by o.customer_id) as cust_lifetime_order_count,

        -- Order sequence & running CLV
        row_number() over (
            partition by o.customer_id 
            order by o.ordered_at, o.order_id
        ) as customer_sales_seq,
        
        sum(o.order_total) over (
            partition by o.customer_id 
            order by o.ordered_at, o.order_id
            rows between unbounded preceding and current row
        ) as customer_lifetime_value

    from {{ ref('fct_orders') }} as o
    left join {{ ref('dim_customers') }} as c
        on o.customer_id = c.customer_id
)

select
    *,
    case 
        when cust_first_order_date = order_placed_at then 'new'
        else 'return' 
    end as nvsr
from orders_enriched