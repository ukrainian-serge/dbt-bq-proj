with
    source as (select * from {{ source("jaffle_shop", "products") }}),
    final as (
        select
            sku,
            name as product_name,
            type as product_type,
            description,
            safe_divide(cast(price as float64), 100) as price
        from source
    )

select *
from final