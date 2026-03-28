-- =====================================================
-- Teardown: Remove all demo objects
--
-- Note:
--   - SNOWFLAKE_QUICKSTART_REPOS (Git integration DB) is NOT dropped
--   - To rebuild, run 00_setup_all.sql after this script
-- =====================================================

USE ROLE ACCOUNTADMIN;

-- Drop demo DB (tables, stages, agents, search services all deleted with it)
DROP DATABASE  IF EXISTS DEMO_INTELLIGENCE_DB;

-- Drop warehouse
DROP WAREHOUSE IF EXISTS DEMO_INTELLIGENCE_WH;

-- Drop roles
DROP ROLE IF EXISTS DEMO_INTELLIGENCE_USER;
DROP ROLE IF EXISTS DEMO_INTELLIGENCE_ADMIN;

-- Optionally revoke Git repo access (uncomment if needed)
-- REVOKE USAGE ON DATABASE SNOWFLAKE_QUICKSTART_REPOS FROM ROLE DEMO_INTELLIGENCE_ADMIN;

SELECT 'Teardown complete. Git integration (SNOWFLAKE_QUICKSTART_REPOS) is preserved.' AS status;
