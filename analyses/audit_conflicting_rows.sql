
{% set old_relation = adapter.get_relation(
      database = "dbt-dev-503215",
      schema = "dbt_skamilchu",
      identifier = "fct_customer_orders_legacy"
) %}

{% set dbt_relation = ref('fct_customer_orders') %}

with audit_diffs as (
    {{ audit_helper.compare_all_columns(    
        a_relation = old_relation,
        b_relation = dbt_relation,
        primary_key = "order_id",
        summarize = false 
    ) }}
) , 

-- Filter only rows where values actually conflict
conflicting_rows as (
    select distinct primary_key as order_id
    from audit_diffs
    where conflicting_values = true 
) 

, final as (
    select
        a.order_id,
        a.fdos as legacy_fdos,
        b.fdos as dbt_fdos,
        DATETIME_DIFF(b.fdos, a.fdos, hour) as fdos_diff

    from (
        select
            order_id,
            fdos
        from {{ old_relation }}
            inner join conflicting_rows using (order_id)
    ) as a
    inner join (
        select
            order_id,
            fdos
        from {{ dbt_relation }}
        inner join conflicting_rows using (order_id)
    ) as b on a.order_id = b.order_id
)

select * from final
