WITH source AS (
    SELECT * FROM {{ source('jaffle_shop', 'stores') }}
)


, final AS (
    SELECT
        id AS store_id
        , name AS store_name
        , CAST(opened_at AS DATETIME) AS opened_at
        , CAST(tax_rate AS FLOAT64) AS tax_rate
    FROM source
)

SELECT * FROM final
