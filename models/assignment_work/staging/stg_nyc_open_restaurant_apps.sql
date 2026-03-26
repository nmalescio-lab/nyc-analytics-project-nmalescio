-- Clean and standardize NYC open restaurant application data
-- One row per application

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
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

        -- Location details
        CAST(zip AS STRING) AS zip,
        CAST(bin AS STRING) AS bin,
        CAST(census_tract AS STRING) AS census_tract,
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council_district,
        CAST(landmarkdistrict_terms AS STRING) AS landmarkdistrict_terms,
        CAST(latitude AS NUMERIC) AS latitude,
        CAST(longitude AS NUMERIC) AS longitude,
        CAST(nta AS STRING) AS nta,

        -- Request details
        CASE
            WHEN REGEXP_CONTAINS(CAST(sla_serial_number AS STRING), r'[A-Za-z]') THEN NULL
            ELSE CAST(TRIM(CAST(sla_serial_number AS STRING)) AS STRING)
        END AS sla_serial_number,

        -- Keep other commonly needed fields from source
        CAST(bulding_number AS STRING) AS bulding_number,
        CAST(sla_license_type AS STRING) AS sla_license_type,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
),

final AS (
    SELECT
        objectid,
        globalid,
        restaurant_name,
        legal_business_name,
        doing_business_as_dba,
        street,
        business_address,

        CASE
            WHEN TRIM(zip) = '' THEN NULL
            WHEN UPPER(TRIM(zip)) IN ('N/A', 'NA') THEN NULL
            WHEN REGEXP_CONTAINS(TRIM(zip), r'^\d{5}$') THEN TRIM(zip)
            ELSE NULL
        END AS zip,

        bin,
        census_tract,
        community_board,
        council_district,
        landmarkdistrict_terms,
        latitude,
        longitude,
        nta,
        sla_serial_number,
        bulding_number,
        sla_license_type,
        _stg_loaded_at
    FROM cleaned
),

deduplicated AS (
    SELECT *
    FROM final
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY objectid
        ORDER BY objectid
    ) = 1
)

SELECT * FROM deduplicated