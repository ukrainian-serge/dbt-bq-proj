{{ config(
  enabled=true
) }}

select
    count(distinct customer_id) as distinct_customer_ids
from {{ ref('fct_customer_orders') }}
where distinct_customer_ids > 1