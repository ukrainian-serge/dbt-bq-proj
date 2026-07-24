WITH orders as (

    select * FROM {{ ref('stg_jaffle_shop__orders') }}
    
),

payments as (

    select * FROM {{ ref('stg_stripe__payments') }}

),

final AS (

    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.status,
        SAFE_DIVIDE(payments.amount, 100) as amount,

    from orders

    left join payments using (order_id)

)

SELECT * FROM final