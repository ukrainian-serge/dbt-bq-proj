{% set get_products_query %}
    select distinct product_name 
    from {{ ref("stg_jaffle_shop__products") }} 
    where product_name is not null 
    order by 1
{% endset %}

{% if execute %}
    {% set results = run_query(get_products_query) %}
    {% set product_names = results.columns[0].values() %}
{% endif %}

{# If the query returns empty or runs during dbt compile, use default fallbacks #}
{# {% if not product_names or product_names | length == 0 %}
    {% set product_names = ["item_a", "item_b"] %}
{% endif %} #}
select
    store_id,
    {% for product_name in product_names %}
        sum(case when product_name = '{{ product_name }}' then order_total else 0 end)
        as total_{{ product_name | replace("-", "_") | replace(" ", "_") | lower }}_sales
        {% if not loop.last %},{% endif %}
    {% endfor %}

from {{ ref("stg_jaffle_shop__orders") }}
group by 1