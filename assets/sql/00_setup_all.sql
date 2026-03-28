-- =====================================================
-- Snowflake Intelligence Demo - Setup All
-- Run this single file to build the entire demo environment.
--
-- Usage:
--   EXECUTE IMMEDIATE FROM
--     @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/00_setup_all.sql;
-- =====================================================

EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/01_configure_account.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/02_data_foundation.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/03_deploy_semantic.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/04_deploy_cortex_search.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/05_deploy_agent.sql;

SELECT 'Setup complete. Open Snowsight > AI & ML > Agents to start the demo.' AS status;
