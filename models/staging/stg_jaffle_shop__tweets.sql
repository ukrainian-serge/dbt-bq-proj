WITH source AS (
    SELECT * FROM {{source('jaffle_shop', 'tweets')}}
)

, final AS (
    SELECT
        id as tweet_id,
        user_id,
        CAST(tweeted_at AS DATETIME) as tweeted_at,
        content as content

    FROM source
)


SELECT * FROM final