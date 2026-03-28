-- =====================================================
-- Step 3: Deploy semantic model
-- Copy YAML from Git repository to internal stage for Cortex Analyst
-- =====================================================

USE ROLE      DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;
USE DATABASE  DEMO_INTELLIGENCE_DB;
USE SCHEMA    ANALYTICS;

-- Stage for semantic model YAML files
CREATE STAGE IF NOT EXISTS DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS
    DIRECTORY = (ENABLE = TRUE);

-- Copy YAML from Git repository to internal stage
COPY FILES
    INTO @DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS
    FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/semantic_models/
    PATTERN = '.*\.yaml';

-- Refresh directory metadata (required after COPY FILES)
ALTER STAGE DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS REFRESH;

-- Verify
SELECT relative_path, size, last_modified
FROM DIRECTORY(@DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS);

SELECT '03_deploy_semantic: done' AS status;
