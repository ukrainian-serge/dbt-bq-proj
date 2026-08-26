-- jinja here grabs distinct product_name from stg_jaffle_shop__products
{% set product_names = dbt_utils.get_column_values(
    table=ref('stg_jaffle_shop__products'),
    column='product_name',
    default=['product_test_dummy1', 'product_test_dummy2', 'product_test_dummy3']
) %}

{# {% set get_products_query %}
    select distinct product_name 
    from {{ ref("stg_jaffle_shop__products") }} 
    where product_name is not null 
    order by 1
{% endset %}

{% if execute %}
    {% set results = run_query(get_products_query) %}
    {% set product_names = results.columns[0].values() %}
{% endif %} #}

with
    cte_orders as (select * from {{ ref("stg_jaffle_shop__orders") }}),
    cte_stores as (select * from {{ ref("stg_jaffle_shop__stores") }}),
    cte_items as (select * from {{ ref("stg_jaffle_shop__items") }}),
    cte_products as (select * from {{ ref("stg_jaffle_shop__products") }}),
    cte_joined as (
        select
            b.store_name,
            c.product_name,
            c.product_type,
            c.description as product_description,
            a.order_total
        from cte_orders as a
        left join cte_stores as b on a.store_id = b.store_id
        left join (
                select distinct
                    a.order_id, b.product_name, b.product_type, b.description
                from cte_items as a
                join cte_products as b using (sku)
            ) as c using (order_id)
    ),

    cte_pivot as (
        select
            coalesce(store_name, 'TOTAL') as store_name,
            {% for product_name in product_names -%}
            round(
                sum(
                    case when product_name = '{{ product_name }}'
                         then order_total
                         else 0
                         end
                ), 2 ) as {{ product_name | replace("-", "_") | replace(" ", "_") | lower }},
            {% endfor -%}

            round(sum(order_total), 0) as TOTAL

        from cte_joined
        group by rollup (store_name)
    ),

    cte_final as (
        select coalesce(store_name, 'TOTAL') as store_name, * except (store_name)
        from cte_pivot
    )

select *
from cte_final