

{% set old_relation = ref('fct_customer_orders_legacy') %}

{% set dbt_relation = ref('fct_customer_orders', v=1) %}

{% if execute %}
{{ audit_helper.compare_relations(
    a_relation = old_relation,
    b_relation = dbt_relation,
    primary_key = "order_id",
) }}

{% endif %} 
