WITH source AS (
    SELECT *
    FROM
        {{ source(
            'jaffle_shop',
            'customers'
        ) }}
),

cleaned AS (
    SELECT
        id AS customer_id,
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(name, r'[^a-zA-Z\s]', ''),
                r'\s+',
                ' '
            )
        ) AS clean_name
    FROM
        source
),

tokens AS (
    SELECT
        customer_id,
        SPLIT(clean_name, ' ') AS name_parts,
        ARRAY_LENGTH(SPLIT(clean_name, ' ')) AS part_count
    FROM
        cleaned
),

final AS (
    SELECT
        customer_id,
        
        -- First Name: First item (if present)
        CASE 
            WHEN part_count >= 1 THEN name_parts[SAFE_OFFSET(0)]
            ELSE NULL 
        END AS first_name,
        
        -- Middle Name: Assigned ONLY if the array has 3 or more items
        CASE 
            WHEN part_count >= 3 THEN name_parts[SAFE_OFFSET(1)]
            ELSE NULL 
        END AS middle_name,
        
        -- Last Name: 
        -- If 2 parts: item at index 1
        -- If 3+ parts: re-joins everything from index 2 onwards (or index 1 if 2 parts)
        CASE 
            WHEN part_count = 2 THEN name_parts[SAFE_OFFSET(1)]
            WHEN part_count >= 3 THEN (
                SELECT STRING_AGG(part, ' ' ORDER BY offset)
                FROM UNNEST(name_parts) AS part WITH OFFSET offset
                WHERE offset >= 2
            )
            ELSE NULL 
        END AS last_name

    FROM
        tokens
)

SELECT *
FROM final
