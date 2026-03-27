-- =====================================================
-- Step 4: Cortex Search サービスのデプロイ
-- サポートケース（非構造化テキスト）の検索インデックスを構築
-- =====================================================

USE ROLE      DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;
USE DATABASE  DEMO_INTELLIGENCE_DB;
USE SCHEMA    ANALYTICS;

-- Cortex Search サービスを作成
-- transcript 列にインデックスを構築し、自然言語検索を可能にする
CREATE OR REPLACE CORTEX SEARCH SERVICE DEMO_INTELLIGENCE_DB.ANALYTICS.SUPPORT_SEARCH
    ON transcript
    ATTRIBUTES category, priority, resolution_status, created_date
    WAREHOUSE  = DEMO_INTELLIGENCE_WH
    TARGET_LAG = '1 hour'
    COMMENT    = 'サポートケース全文検索サービス'
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

SELECT '04_deploy_cortex_search: 完了（インデックス構築は非同期で実行中）' AS status;
