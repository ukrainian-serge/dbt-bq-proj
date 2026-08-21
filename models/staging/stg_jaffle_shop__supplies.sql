with
    source as (select * from {{ source("jaffle_shop", "supplies") }}),
    final as (
        select
            id as supply_id,
            name as supplies_name,
            cast(perishable as boolean) as perishable,
            sku,
            safe_divide(cast(cost as float64), 100) as cost
        from source
    )

select *
from final