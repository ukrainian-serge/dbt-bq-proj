WITH stg AS (
    SELECT
        id as tweet_id,
        user_id,
        CAST(tweeted_at AS DATETIME) as tweeted_at,
        content as content

    FROM {{source('jaffle_shop', 'tweets')}}
)


, final AS (
    SELECT
        tweet_id,
        user_id,
        tweeted_at,
        content

    FROM stg
)


SELECT * FROM final