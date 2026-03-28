-- =====================================================
-- Step 5: Cortex Agent のデプロイ
-- Cortex Analyst（構造化分析）+ Cortex Search（FAQ検索）を
-- 組み合わせたエージェントを作成する
--
-- CREATE CORTEX AGENT は Preview 機能のため、SQL 未サポートの場合は
-- エラーをスキップし、Snowsight UI での手動作成を案内する。
-- =====================================================

USE ROLE      DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;
USE DATABASE  DEMO_INTELLIGENCE_DB;
USE SCHEMA    ANALYTICS;

-- エージェント作成（SQL未サポートの場合はスキップ）
BEGIN
    CREATE OR REPLACE CORTEX AGENT DEMO_INTELLIGENCE_DB.ANALYTICS.DEMO_SALES_AGENT
        COMMENT = '小売デモ用 Snowflake Intelligence エージェント。売上・商品・キャンペーン・サポートに関する質問に自然言語で答えます。'
        TOOLS = (
            CORTEX_ANALYST_TOOL(
                semantic_model => '@DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS/demo_sales_model.yaml'
            ),
            CORTEX_SEARCH_TOOL(
                service => 'DEMO_INTELLIGENCE_DB.ANALYTICS.SUPPORT_SEARCH'
            )
        )
        TOOL_RESOURCES = (
            CORTEX_SEARCH_TOOL(max_results => 5)
        );
EXCEPTION
    WHEN OTHER THEN
        -- SQL未サポートの場合はスキップ（手動作成の案内は以下のSELECTで表示）
        NULL;
END;

SELECT '05_deploy_agent: 完了' AS status;
SELECT 'エージェントが未作成の場合は Snowsight > AI & ML > Agents > Create Agent から手動作成してください（README参照）' AS next_step;
