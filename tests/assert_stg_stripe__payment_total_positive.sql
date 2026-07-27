-- Refunds have a negative amount, so the total amount should always be >= 0.
-- Therefore return records where this isn't true to make the test fail.
-- below is opposite of what we want. If below returns any rows, it fails test



SELECT 
    order_id,
    SUM(amount) AS total_amount
FROM {{ ref('stg_stripe__payments') }}
GROUP BY order_id
HAVING total_amount < 0