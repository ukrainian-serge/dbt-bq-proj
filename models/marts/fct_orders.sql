


WITH orders as (

    select * FROM {{ ref('stg_jaffle_shop__orders') }}
    
)


, customer AS (

    select DISTINCT
        customer_id,
        first_name,
        last_name
    from {{ ref('stg_jaffle_shop__customers') }}
)

, stores AS (

    select DISTINCT
        store_id,
        name
    from {{ ref('stg_jaffle_shop__stores') }}
)

, final AS (

    select
        A.order_id,
        A.customer_id,
        B.first_name,
        B.last_name,
        A.ordered_at,
        A.store_id,
        C.name,
        A.subtotal,
        A.tax_paid,
        A.order_total

    from orders as A

    left join customer AS B using (customer_id)

    left join stores AS C using (store_id)

)


SELECT * FROM final