{% macro grant_select(schema=target.dataset, database=target.database, role="roles/bigquery.dataViewer", principal="") %}
    {% set sql %}
        GRANT `{{ role }}`
        ON SCHEMA `{{ database }}`.`{{ schema }}`
        TO "{{ principal }}";
    {% endset %}

    {% do run_query(sql) %}
    {% do log("Granted " ~ role ~ " on " ~ database ~ "." ~ schema ~ " to " ~ principal, info=True) %}
{% endmacro %}