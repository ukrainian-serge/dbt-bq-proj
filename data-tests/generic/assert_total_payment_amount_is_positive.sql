{{ config(
  enabled=false
) }}

select 
    total_amount_paid    
from {{ ref('fct_customer_orders') }}
where total_amount_paid >= 0