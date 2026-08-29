{% macro find_datatypes(model_name) %}
    {% set relation = ref(model_name) %}
    {% set cols = adapter.get_columns_in_relation(relation) %}
    {%- for col in cols %}
    {{ print(
        "- name: " ~ col.name | 
        lower ~ "\n  data_type: " ~ col.dtype | lower
        ) }}
    {%- endfor %}
{% endmacro %}




{% macro list_all_model_datatypes() %}
    {% if execute %}
        {% for node in graph.nodes.values() %}
            {% if node.resource_type == 'model' and node.package_name == project_name %}
                {{ print('\n' ~ node.name) }}
                {% set relation = ref(node.name) %}
                {% set cols = adapter.get_columns_in_relation(relation) %}
                {% for col in cols %}
                    {{ print('  - name: ' ~ col.name | lower ~ '\n    data_type: ' ~ col.dtype | lower) }}
                {% endfor %}
            {% endif %}
        {% endfor %}
    {% endif %}
{% endmacro %}