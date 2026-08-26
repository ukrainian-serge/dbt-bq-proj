{% macro union_tables_by_prefix(database, schema, prefix) %}

    {% if execute %}
        {% set tables = dbt_utils.get_relations_by_prefix(
            schema=schema, 
            prefix=prefix,
            database=database
        ) %}

        {% for table in tables %}
            {% do log("Found table: " ~ table, info=True) %}
        {% endfor %}

    {% else %}
        select 1 as id where false
    {% endif %}

{% endmacro %}