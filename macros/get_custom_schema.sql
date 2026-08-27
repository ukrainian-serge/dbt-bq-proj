{% macro generate_schema_name(custom_schema_name) -%}

    {%- if custom_schema_name is none or target.name == 'dev' -%}

        {{ return(target.schema) }}

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}