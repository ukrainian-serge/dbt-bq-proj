with
    source as (select * from {{ source("jaffle_shop", "items") }}),

    final as (
        select 
            id as item_id, 
            order_id, 
            sku 
        from source)

select *
from final