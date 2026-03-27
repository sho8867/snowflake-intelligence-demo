-- =====================================================
-- Step 5: Cortex Agent のデプロイ
-- Cortex Analyst（構造化分析）+ Cortex Search（FAQ検索）を
-- 組み合わせたエージェントを作成する
--
-- 注意: CREATE AGENT の SQL 構文は Preview 機能のため
--       アカウント設定によっては UI 手動作成が必要な場合があります。
--       エラーが発生した場合は README.md の「手動エージェント作成」を参照してください。
-- =====================================================

USE ROLE      DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;
USE DATABASE  DEMO_INTELLIGENCE_DB;
USE SCHEMA    ANALYTICS;

-- エージェントを作成
-- Cortex Analyst ツール: セマンティックモデル YAML を参照して SQL を自動生成
-- Cortex Search ツール: サポートケース全文検索
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

SELECT '05_deploy_agent: 完了' AS status;
SELECT 'エージェントは Snowsight > AI & ML > Agents から利用できます' AS next_step;
