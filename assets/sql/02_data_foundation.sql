-- =====================================================
-- Step 2: データ基盤構築
-- テーブル作成 + Git リポジトリ内 CSV からデータロード
-- =====================================================

USE ROLE      DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;
USE DATABASE  DEMO_INTELLIGENCE_DB;
USE SCHEMA    ANALYTICS;

-- =====================================================
-- テーブル定義
-- =====================================================

-- 商品マスタ
CREATE OR REPLACE TABLE PRODUCTS (
    product_id    VARCHAR(20)    NOT NULL COMMENT '商品ID',
    product_name  VARCHAR(100)   NOT NULL COMMENT '商品名',
    category      VARCHAR(50)    NOT NULL COMMENT '大カテゴリ（家電, 衣料品, 食品, スポーツ, 美容・健康）',
    subcategory   VARCHAR(50)    COMMENT 'サブカテゴリ',
    unit_price    NUMBER(10, 2)  NOT NULL COMMENT '販売単価（円）',
    cost_price    NUMBER(10, 2)  NOT NULL COMMENT '原価（円）',
    PRIMARY KEY (product_id)
);

-- 売上トランザクション
CREATE OR REPLACE TABLE SALES (
    sale_id      VARCHAR(20)    NOT NULL COMMENT '売上ID',
    sale_date    DATE           NOT NULL COMMENT '売上日',
    product_id   VARCHAR(20)    NOT NULL COMMENT '商品ID',
    product_name VARCHAR(100)   COMMENT '商品名',
    category     VARCHAR(50)    COMMENT '大カテゴリ',
    subcategory  VARCHAR(50)    COMMENT 'サブカテゴリ',
    region       VARCHAR(50)    COMMENT '地域（関東, 関西, 東海 等）',
    store_id     VARCHAR(20)    COMMENT '店舗ID',
    units_sold   NUMBER(10)     NOT NULL COMMENT '販売数量',
    revenue      NUMBER(12, 2)  NOT NULL COMMENT '売上金額（円）',
    cost         NUMBER(12, 2)  COMMENT '原価合計（円）',
    PRIMARY KEY (sale_id)
);

-- マーケティングキャンペーン
CREATE OR REPLACE TABLE CAMPAIGNS (
    campaign_id   VARCHAR(20)    NOT NULL COMMENT 'キャンペーンID',
    campaign_name VARCHAR(100)   NOT NULL COMMENT 'キャンペーン名',
    category      VARCHAR(50)    COMMENT '対象カテゴリ',
    channel       VARCHAR(50)    COMMENT 'チャネル（SNS広告, メールマーケティング 等）',
    start_date    DATE           COMMENT '開始日',
    end_date      DATE           COMMENT '終了日',
    budget        NUMBER(12, 2)  COMMENT '予算（円）',
    actual_spend  NUMBER(12, 2)  COMMENT '実績費用（円）',
    impressions   NUMBER(12)     COMMENT 'インプレッション数',
    clicks        NUMBER(10)     COMMENT 'クリック数',
    conversions   NUMBER(10)     COMMENT 'コンバージョン数',
    PRIMARY KEY (campaign_id)
);

-- サポートケース（Cortex Search 用）
CREATE OR REPLACE TABLE SUPPORT_CASES (
    case_id           VARCHAR(20)   NOT NULL COMMENT 'ケースID',
    created_date      DATE          NOT NULL COMMENT '受付日',
    category          VARCHAR(50)   COMMENT '商品カテゴリ',
    priority          VARCHAR(10)   COMMENT '優先度（高, 中, 低）',
    transcript        TEXT          COMMENT 'お問い合わせ内容・対応記録',
    resolution_status VARCHAR(20)   COMMENT '解決ステータス（解決済み, 対応中, 未対応）',
    PRIMARY KEY (case_id)
);

-- =====================================================
-- Git リポジトリ内 CSV からデータロード
-- =====================================================

COPY INTO PRODUCTS
FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/data/products.csv
FILE_FORMAT = (
    TYPE                        = 'CSV'
    SKIP_HEADER                 = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF                     = ('NULL', 'null', '')
    ENCODING                    = 'UTF-8'
);

COPY INTO SALES
FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/data/sales.csv
FILE_FORMAT = (
    TYPE                        = 'CSV'
    SKIP_HEADER                 = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF                     = ('NULL', 'null', '')
    ENCODING                    = 'UTF-8'
);

COPY INTO CAMPAIGNS
FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/data/campaigns.csv
FILE_FORMAT = (
    TYPE                        = 'CSV'
    SKIP_HEADER                 = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF                     = ('NULL', 'null', '')
    ENCODING                    = 'UTF-8'
);

COPY INTO SUPPORT_CASES
FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/data/support_cases.csv
FILE_FORMAT = (
    TYPE                        = 'CSV'
    SKIP_HEADER                 = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF                     = ('NULL', 'null', '')
    ENCODING                    = 'UTF-8'
);

-- ロード結果確認
SELECT 'PRODUCTS'     AS table_name, COUNT(*) AS row_count FROM PRODUCTS     UNION ALL
SELECT 'SALES'        AS table_name, COUNT(*) AS row_count FROM SALES         UNION ALL
SELECT 'CAMPAIGNS'    AS table_name, COUNT(*) AS row_count FROM CAMPAIGNS     UNION ALL
SELECT 'SUPPORT_CASES'AS table_name, COUNT(*) AS row_count FROM SUPPORT_CASES;

SELECT '02_data_foundation: 完了' AS status;
