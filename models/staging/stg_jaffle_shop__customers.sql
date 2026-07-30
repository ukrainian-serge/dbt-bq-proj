WITH stg AS (

select
    id as customer_id,
    name as first_and_last_name,
from {{ source('jaffle_shop', 'customers') }}

)

, trimmed as (
    SELECT 
        customer_id,
        TRIM(first_and_last_name) as first_and_last_name
    FROM stg
)

, final as (
    SELECT 
        customer_id,
        split(first_and_last_name, ' ')[safe_offset(0)] as first_name,
        split(first_and_last_name, ' ')[safe_offset(1)] as last_name,
    FROM trimmed
)

SELECT * FROM final