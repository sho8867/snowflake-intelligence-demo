-- =====================================================
-- Step 5: Deploy Cortex Agent
-- Combines Cortex Analyst (structured queries) and
-- Cortex Search (unstructured FAQ search)
--
-- CREATE CORTEX AGENT is a Preview feature.
-- If SQL is unsupported, create the agent manually via
-- Snowsight > AI & ML > Agents > Create Agent (see README).
-- =====================================================

USE ROLE      DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;
USE DATABASE  DEMO_INTELLIGENCE_DB;
USE SCHEMA    ANALYTICS;

-- Wrap in EXECUTE IMMEDIATE so compilation errors are caught as runtime errors
BEGIN
    EXECUTE IMMEDIATE $$
        CREATE OR REPLACE CORTEX AGENT DEMO_INTELLIGENCE_DB.ANALYTICS.DEMO_SALES_AGENT
            COMMENT = 'Retail demo agent for Snowflake Intelligence'
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
            )
    $$;
EXCEPTION
    WHEN OTHER THEN
        NULL; -- SQL not yet supported: create agent manually via Snowsight UI
END;

SELECT '05_deploy_agent: done' AS status;
SELECT 'If agent was not created by SQL, go to Snowsight > AI & ML > Agents > Create Agent (see README)' AS next_step;
