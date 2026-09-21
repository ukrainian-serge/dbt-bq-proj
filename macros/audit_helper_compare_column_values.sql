
{% macro audit_helper_compare_column_values( old_model, new_model) %}
{#
USAGE EXAMPLE:
    dbt run-operation audit_helper_compare_column_values --args '{"old_model": "fct_customer_orders_legacy", "new_model": "fct_customer_orders"}'  
#}
{%- set columns_to_compare = adapter.get_columns_in_relation(ref( old_model )) -%}

{% set old_etl_relation_query %}
  select * from {{ ref( old_model ) }}
{% endset %}

{% set new_etl_relation_query %}
  select * from {{ ref( new_model ) }}
{% endset %}
  
{% if execute %}
    {% for column in columns_to_compare %}
        {{ log('Comparing column "' ~ column.name ~ '"', info=True) }}
        {% set audit_query = audit_helper.compare_column_values(
            a_query=old_etl_relation_query,
            b_query=new_etl_relation_query,
            primary_key='order_id',
            column_to_compare=column.name
        ) %}
        
        {% set audit_results = run_query(audit_query) %}

        {# Force output through dbt's log stream #}
        {% do log(audit_results.column_names | join(' | '), info=True) %}
        
        {% for row in audit_results.rows %}
            {% do log(row.values() | join(' | '), info=True) %}
        {% endfor %}

        {# Blank line separator #}
        {% do log("", info=True) %}

        {# {% endfor %} #}
    {% endfor %}
{% endif %}
{% endmacro %}