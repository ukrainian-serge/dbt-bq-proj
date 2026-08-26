{% macro clean_stale_models(database=target.database, schema=target.schema, days=7, dry_run=True) %}

    {% set get_drop_commands_query %}
    
        with cte as (
            select 
                project_id,
                dataset_id,
                table_id,
                creation_time,
                timestamp_millis(last_modified_time)  as last_modified_time,
                row_count,
                size_bytes,
                ROUND(size_bytes / POW(10, 9), 2) AS size_gb,
                case when type = 2 then 'VIEW' else 'TABLE' end as type
            from `{{ database }}`.`{{ schema }}`.__TABLES__
            )

            select
                type,
                'DROP ' || type || ' `' || project_id || '`.`' || dataset_id || '`.`' || table_id || '`;' as drop_statement
            from cte
            where last_modified_time <= timestamp_sub(current_timestamp(), interval {{ days }} day)

        {% endset %}

    {# Print the compiled query to the terminal during the execution phase #}
    {% if execute %}
        {{ log('\n--- COMPILED SQL QUERY ---', info=True) }}
        {{ log(get_drop_commands_query, info=True) }}
        {{ log('---------------------------\n', info=True) }}
    {% endif %}

    {% if execute %}
        {{ log('\nGenerating cleanup queries...\n', info=True) }}
        {% set drop_queries = run_query(get_drop_commands_query).columns[1].values() %}

        {% for query in drop_queries %}
            {% if dry_run %}
                {{ log(query, info=True) }}
            {% else %}
                {{ log('Dropping object with command: ' ~ query, info=True) }}
                {% do run_query(query) %} 
            {% endif %}       
        {% endfor %}
    {% endif %}
    
{% endmacro %}