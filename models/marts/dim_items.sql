
with items as (

    select * FROM {{ ref('stg_jaffle_shop__items') }}

),

orders as (

    select * FROM {{ ref('stg_jaffle_shop__orders') }}
    
),

products as (

    select * FROM {{ ref('stg_jaffle_shop__products') }}
    
),


orders_agg as (

    select
        order_id,
        sum(subtotal) as subtotal,
        sum(tax_paid) as tax_paid,
        sum(order_total) as order_total

    from orders

    group by 1

)

, final as (

    select
        A.order_id,
        C.sku as product_sku,
        C.name as product_name,
        C.type as product_type,
        C.price,
        A.subtotal,
        A.tax_paid,
        A.order_total

    from orders_agg as A

    left join items AS B using (order_id)

    left join products AS C 
        ON B.sku = C.sku

)


select * from final
