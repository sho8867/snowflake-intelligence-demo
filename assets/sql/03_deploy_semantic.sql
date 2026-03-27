-- =====================================================
-- Step 3: セマンティックモデルのデプロイ
-- YAML ファイルを内部ステージへコピーして Cortex Analyst に登録
-- =====================================================

USE ROLE      DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;
USE DATABASE  DEMO_INTELLIGENCE_DB;
USE SCHEMA    ANALYTICS;

-- セマンティックモデル用ステージを作成
CREATE STAGE IF NOT EXISTS DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS
    DIRECTORY = (ENABLE = TRUE)
    COMMENT   = 'Cortex Analyst セマンティックモデル格納用ステージ';

-- Git リポジトリ内の YAML を内部ステージへコピー
COPY FILES
    INTO @DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS
    FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/semantic_models/
    PATTERN = '.*\.yaml';

-- ステージ内容を確認
SELECT relative_path, size, last_modified
FROM DIRECTORY(@DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS);

SELECT '03_deploy_semantic: 完了' AS status;
