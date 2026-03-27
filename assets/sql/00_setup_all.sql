-- =====================================================
-- Snowflake Intelligence Demo - Setup All
-- このファイル1つで全デモ環境が構築される
--
-- 実行方法:
--   EXECUTE IMMEDIATE FROM
--     @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/00_setup_all.sql;
-- =====================================================

EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/01_configure_account.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/02_data_foundation.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/03_deploy_semantic.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/04_deploy_cortex_search.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/05_deploy_agent.sql;

SELECT 'デモ環境の構築が完了しました。Snowsight > AI & ML > Agents からエージェントを開いてください。' AS status;
