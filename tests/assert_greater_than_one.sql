{{
  config(
    severity="warn",
    enabled=false
    )
}}


select
    order_id,
    order_total_amount_paid,
from {{ ref('int_customer_orders') }}
where order_total_amount_paid <= 1