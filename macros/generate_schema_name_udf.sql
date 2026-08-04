{% macro generate_schema_name(custom_schema_name, node) %}
    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is not none and node.resource_type == 'function' -%}
        {# BIGQUERY UDFs: Use the custom schema name EXACTLY (e.g., 'shared_udfs') #}
        {{ custom_schema_name | trim }}

    {%- elif custom_schema_name is not none -%}
        {# MODELS/SEEDS: Append to personal schema (e.g., 'dbt_skamilchu_marketing') #}
        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- else -%}
        {# NO CUSTOM SCHEMA: Use personal schema (e.g., 'dbt_skamilchu') #}
        {{ default_schema }}

    {%- endif -%}
{% endmacro %}   