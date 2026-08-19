WITH source AS (
    SELECT * FROM {{ source('jaffle_shop', 'tweets') }}
)

, final AS (
    SELECT
        id AS tweet_id
        , user_id
        , CAST(tweeted_at AS DATETIME) AS tweeted_at
        , content

    FROM source
)


SELECT * FROM final
