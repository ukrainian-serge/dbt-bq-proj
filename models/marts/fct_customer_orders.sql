with 

stg_customers AS (
    SELECT * FROM {{ ref('dim_customers') }}
)

, stg_orders AS (
    SELECT * FROM {{ ref('fct_orders') }}
)



, customer_orders AS (
    SELECT
        o.order_id,
        o.customer_id,
        c.first_name as customer_first_name,
        c.last_name as customer_last_name,   
        o.order_total as order_total,

        min(o.ordered_at) over (partition by o.customer_id) as customer_first_order_date,
        max(o.ordered_at) over (partition by o.customer_id) as customer_most_recent_order_date,
        count(o.order_id) over (partition by o.customer_id) as customer_lifetime_order_count,
        o.ordered_at as order_date,

    from stg_orders as o
    left join stg_customers as c on o.customer_id = c.customer_id
    GROUP BY ALL

)



, final as (
    select 
        *,
        case
            when order_date = customer_first_order_date then 'new'
            else 'return'
        end as nvsr,

        -- Order sequence & running CLV
        row_number() over (
            partition by customer_id
            order by order_date,
                order_id
        ) as customer_sales_seq,

        sum(order_total) over (
            partition by customer_id
            order by order_date,
                order_id rows between unbounded preceding and current row
        ) as customer_lifetime_value

    from customer_orders
)

select * from final