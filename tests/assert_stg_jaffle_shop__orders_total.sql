-- Refunds have a negative amount, so the total amount should always be >= 0.
-- Therefore return records where this isn't true to make the test fail.
-- below is opposite of what we want. If below returns any rows, it fails test



SELECT 
    order_id,
    SUM(order_total) AS order_total
FROM {{ ref('stg_jaffle_shop__orders') }}
GROUP BY order_id
HAVING order_total < 0