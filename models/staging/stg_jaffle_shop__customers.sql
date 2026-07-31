WITH source AS (

select * from {{ source('jaffle_shop', 'customers') }}

)

, trimmed as (
    SELECT 
        id as customer_id,
        TRIM(name) as first_and_last_name
    FROM source
)

, final as (
    SELECT 
        customer_id,
        split(first_and_last_name, ' ')[safe_offset(0)] as first_name,
        split(first_and_last_name, ' ')[safe_offset(1)] as last_name,
    FROM trimmed
)

SELECT * FROM final