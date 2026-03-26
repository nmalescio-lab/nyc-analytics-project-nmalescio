-- Clean and standardize NYC open restaurant application data
-- One row per application

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        * EXCEPT (
            objectid,
            globalid,
            restaurant_name,
            legal_business_name,
            doing_business_as_dba,
            street,
            business_address,
            zip,
            sla_serial_number
        ),

        -- Identifiers
        CAST(objectid AS STRING) AS objectid,
        CAST(
            LOWER(
                REGEXP_REPLACE(
                    TRIM(CAST(globalid AS STRING)),
                    r'^\{|\}$',
                    ''
                )
            ) AS STRING
        ) AS globalid,

        -- Restaurant details
        CAST(INITCAP(TRIM(CAST(restaurant_name AS STRING))) AS STRING) AS restaurant_name,
        CAST(INITCAP(TRIM(CAST(legal_business_name AS STRING))) AS STRING) AS legal_business_name,
        CAST(INITCAP(TRIM(CAST(doing_business_as_dba AS STRING))) AS STRING) AS doing_business_as_dba,

        -- Address details
        CAST(INITCAP(TRIM(CAST(street AS STRING))) AS STRING) AS street,
        CAST(INITCAP(TRIM(CAST(business_address AS STRING))) AS STRING) AS business_address,

        -- Zip code cleaning
        CASE
            WHEN TRIM(CAST(zip AS STRING)) = '' THEN NULL
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN REGEXP_CONTAINS(TRIM(CAST(zip AS STRING)), r'^\d{5}$') THEN TRIM(CAST(zip AS STRING))
            ELSE NULL
        END AS zip,

        -- Request details
        CASE
            WHEN REGEXP_CONTAINS(CAST(sla_serial_number AS STRING), r'[A-Za-z]') THEN NULL
            ELSE CAST(TRIM(CAST(sla_serial_number AS STRING)) AS STRING)
        END AS sla_serial_number,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
),

deduplicated AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY objectid
        ORDER BY
            CASE WHEN bin IS NOT NULL THEN 1 ELSE 0 END DESC,
            CASE WHEN census_tract IS NOT NULL THEN 1 ELSE 0 END DESC,
            CASE WHEN community_board IS NOT NULL THEN 1 ELSE 0 END DESC,
            CASE WHEN council_district IS NOT NULL THEN 1 ELSE 0 END DESC,
            CASE WHEN landmarkdistrict_terms IS NOT NULL THEN 1 ELSE 0 END DESC,
            CASE WHEN latitude IS NOT NULL THEN 1 ELSE 0 END DESC,
            CASE WHEN longitude IS NOT NULL THEN 1 ELSE 0 END DESC,
            CASE WHEN nta IS NOT NULL THEN 1 ELSE 0 END DESC
    ) = 1
)

SELECT * FROM deduplicated