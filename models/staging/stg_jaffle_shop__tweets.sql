with
    source as (select * from {{ source("jaffle_shop", "tweets") }}),
    final as (
        select
            id as tweet_id, user_id, cast(tweeted_at as datetime) as tweeted_at, content

        from source
    )

select *
from final