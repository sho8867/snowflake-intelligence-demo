-- =====================================================
-- Step 4: Deploy Cortex Search service
-- Build full-text search index on support case transcripts
-- =====================================================

USE ROLE      DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;
USE DATABASE  DEMO_INTELLIGENCE_DB;
USE SCHEMA    ANALYTICS;

CREATE OR REPLACE CORTEX SEARCH SERVICE DEMO_INTELLIGENCE_DB.ANALYTICS.SUPPORT_SEARCH
    ON transcript
    ATTRIBUTES category, priority, resolution_status, created_date
    WAREHOUSE  = DEMO_INTELLIGENCE_WH
    TARGET_LAG = '1 hour'
    AS (
        SELECT
            case_id,
            created_date,
            category,
            priority,
            transcript,
            resolution_status
        FROM DEMO_INTELLIGENCE_DB.ANALYTICS.SUPPORT_CASES
    );

SELECT '04_deploy_cortex_search: done (index building asynchronously)' AS status;
