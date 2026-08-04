


WITH orders as (

    select * FROM {{ ref('stg_jaffle_shop__orders') }}
    
)


, joined AS (

    select
        A.order_id,
        A.customer_id,

        A.ordered_at,

        sum(order_total) over (
            PARTITION BY order_id
            ) as order_total_amount_paid,

        max(A.ordered_at) over (partition by A.order_id) as order_finalized_date,

        max(A.ordered_at) over (partition by A.customer_id) as customer_most_recent_order_date,

        count(*) over (partition by A.customer_id) as customer_lifetime_order_count,

        row_number() over (
            order by order_id
            ) as transaction_seq,

        -- Order sequence & running CLV
        row_number() over (
            partition by customer_id
            order by A.ordered_at,
                order_id
        ) as customer_sales_seq,

        -- nvsr goes here

        sum(A.order_total) over (
            partition by customer_id
            order by A.ordered_at,
                order_id rows between unbounded preceding and current row
        ) as customer_lifetime_value,

        min(A.ordered_at) over (partition by A.customer_id) as customer_first_order_date,



    from orders as A
    WHERE order_total > 0

)

, final AS (
    SELECT
        *,

        {{ function('divide_udf')}} (
            
            customer_lifetime_value,
            customer_lifetime_order_count
            
        ) as customer_avg_non_returned_order_value


    FROM joined
)


SELECT * FROM final