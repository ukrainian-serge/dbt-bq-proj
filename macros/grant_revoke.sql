{% macro grant_revoke(
    switch=true,
    database=target.database,
    schema=target.schema,  
    role="roles/bigquery.dataViewer", 
    principal="example@email.com"
    ) 
    %}
    
    {% if switch %}
        {% set action = 'GRANT' %}
        {% set prep = 'TO' %}
    {% else %}
        {% set action = 'REVOKE' %}
        {% set prep = 'FROM' %}
    {% endif %}

    {% set sql %}
        {{ action }} `{{ role }}`
        ON SCHEMA `{{ database }}`.`{{ schema }}`
        {{ prep }} "{{ principal }}";
    {% endset %}

    {% do run_query(sql) %}
    {% do log("switch_term " ~ role ~ " on " ~ database ~ "." ~ schema ~ " to " ~ principal, info=True) %}
{% endmacro %}

