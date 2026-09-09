{% macro clean_empty_tables(database=target.database, schema=target.schema, dry_run=True) %}

    {% set get_drop_commands_query %}
        with cte as (
            select 
                project_id,
                dataset_id,
                table_id,
                row_count,
                case when type = 2 then 'VIEW' else 'TABLE' end as type
            from `{{ database }}`.`{{ schema }}`.__TABLES__
        )

        select
            type,
            'DROP ' || type || ' `' || project_id || '`.`' || dataset_id || '`.`' || table_id || '`;' as drop_statement
        from cte
        -- Filter specifically for empty physical tables (type != 2 excludes views, as views show 0 row_count in __TABLES__)
        where row_count = 0
          and type = 'TABLE'
    {% endset %}

    {% if execute %}
        {{ log('\n--- COMPILED SQL QUERY ---', info=True) }}
        {{ log(get_drop_commands_query, info=True) }}
        {{ log('---------------------------\n', info=True) }}

        {{ log('Scanning for empty tables to drop...\n', info=True) }}
        {% set drop_queries = run_query(get_drop_commands_query).columns[1].values() %}

        {% if drop_queries | length == 0 %}
            {{ log('No empty tables found in ' ~ database ~ '.' ~ schema, info=True) }}
        {% else %}
            {% for query in drop_queries %}
                {% if dry_run %}
                    {{ log('[DRY RUN] ' ~ query, info=True) }}
                {% else %}
                    {{ log('Executing: ' ~ query, info=True) }}
                    {% do run_query(query) %}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endif %}

{% endmacro %}