-- Clean and standardize NYC open restaurant application data
-- One row per application

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

final AS (
    SELECT
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

        CAST(INITCAP(TRIM(CAST(restaurant_name AS STRING))) AS STRING) AS restaurant_name,
        CAST(INITCAP(TRIM(CAST(legal_business_name AS STRING))) AS STRING) AS legal_business_name,
        CAST(INITCAP(TRIM(CAST(doing_business_as_dba AS STRING))) AS STRING) AS doing_business_as_dba,

        CAST(INITCAP(TRIM(CAST(street AS STRING))) AS STRING) AS street,
        CAST(INITCAP(TRIM(CAST(business_address AS STRING))) AS STRING) AS business_address,

        CASE
            WHEN TRIM(CAST(zip AS STRING)) = '' THEN NULL
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN REGEXP_CONTAINS(TRIM(CAST(zip AS STRING)), r'^\d{5}$') THEN TRIM(CAST(zip AS STRING))
            ELSE NULL
        END AS zip,

        CAST(bin AS STRING) AS bin,
        CAST(census_tract AS STRING) AS census_tract,
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council_district,
        CAST(landmarkdistrict_terms AS STRING) AS landmarkdistrict_terms,
        CAST(latitude AS NUMERIC) AS latitude,
        CAST(longitude AS NUMERIC) AS longitude,
        CAST(nta AS STRING) AS nta,

        CASE
            WHEN REGEXP_CONTAINS(CAST(sla_serial_number AS STRING), r'[A-Za-z]') THEN NULL
            ELSE CAST(TRIM(CAST(sla_serial_number AS STRING)) AS STRING)
        END AS sla_serial_number,

        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
)

SELECT * FROM final