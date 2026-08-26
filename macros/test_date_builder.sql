{# {% macro test_date_builder(
    date_column,
    start_date, 
    end_date=none,
    ) %}
    {% set end = end_date or modules.datetime.date.today().strftime('%Y-%m-%d') %}
    {% set query %}
        select count(*) from {{ ref('stg_jaffle_shop__orders') }} 
        where {{ date_column }} between '{{ start_date }}' and '{{ end }}'
    {% endset %}
    
    {% do log("Generated Query: " ~ query, info=True) %}
    {% set results = run_query(query) %}
    {% do results.print_table() %}
{% endmacro %} #}

{% macro test_date_builder(
    model_name,
    date_column,
    start_date, 
    end_date=none
) %}
    {% set end = end_date or modules.datetime.date.today().strftime('%Y-%m-%d') %}
    {% set query %}
        select count(*) as order_count from {{ ref(model_name) }} 
        where {{ date_column }} between '{{ start_date }}' and '{{ end }}'
    {% endset %}
    
    {% do log("Generated Query: " ~ query, info=True) %}
    
    {% set results = run_query(query) %}
    
    {% if execute %}
        {# Extract the actual value from row 0, column 0 #}
        {% set val = results.columns[0][0] %}
        {% do log("QueryResult: " ~ val, info=True) %}
    {% endif %}
{% endmacro %}