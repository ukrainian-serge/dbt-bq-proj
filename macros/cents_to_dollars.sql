{%-  macro cents_to_dollars(column_name, decimals=0) -%}

    round({{ column_name }} * 1.0 / 100, {{ decimals }})

{%- endmacro -%}