-- =====================================================
-- Step 2: Data foundation
-- Create tables and load CSV data from Git repository
-- =====================================================

USE ROLE      DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;
USE DATABASE  DEMO_INTELLIGENCE_DB;
USE SCHEMA    ANALYTICS;

-- =====================================================
-- Table definitions
-- =====================================================

-- Product master
CREATE OR REPLACE TABLE PRODUCTS (
    product_id    VARCHAR(20)   NOT NULL,
    product_name  VARCHAR(100)  NOT NULL,
    category      VARCHAR(50)   NOT NULL,
    subcategory   VARCHAR(50),
    unit_price    NUMBER(10, 2) NOT NULL,
    cost_price    NUMBER(10, 2) NOT NULL,
    PRIMARY KEY (product_id)
);

-- Sales transactions
CREATE OR REPLACE TABLE SALES (
    sale_id      VARCHAR(20)   NOT NULL,
    sale_date    DATE          NOT NULL,
    product_id   VARCHAR(20)   NOT NULL,
    product_name VARCHAR(100),
    category     VARCHAR(50),
    subcategory  VARCHAR(50),
    region       VARCHAR(50),
    store_id     VARCHAR(20),
    units_sold   NUMBER(10)    NOT NULL,
    revenue      NUMBER(12, 2) NOT NULL,
    cost         NUMBER(12, 2),
    PRIMARY KEY (sale_id)
);

-- Marketing campaigns
CREATE OR REPLACE TABLE CAMPAIGNS (
    campaign_id   VARCHAR(20)   NOT NULL,
    campaign_name VARCHAR(100)  NOT NULL,
    category      VARCHAR(50),
    channel       VARCHAR(50),
    start_date    DATE,
    end_date      DATE,
    budget        NUMBER(12, 2),
    actual_spend  NUMBER(12, 2),
    impressions   NUMBER(12),
    clicks        NUMBER(10),
    conversions   NUMBER(10),
    PRIMARY KEY (campaign_id)
);

-- Support cases (for Cortex Search)
CREATE OR REPLACE TABLE SUPPORT_CASES (
    case_id           VARCHAR(20)  NOT NULL,
    created_date      DATE         NOT NULL,
    category          VARCHAR(50),
    priority          VARCHAR(10),
    transcript        TEXT,
    resolution_status VARCHAR(20),
    PRIMARY KEY (case_id)
);

-- =====================================================
-- Load data: Git repo -> internal stage -> tables
-- (COPY INTO from Git Repository is not supported;
--  use COPY FILES to an internal stage first)
-- =====================================================

-- Internal stage for raw CSV files
CREATE STAGE IF NOT EXISTS DEMO_INTELLIGENCE_DB.ANALYTICS.RAW_DATA;

-- Copy CSV files from Git repository to internal stage
COPY FILES
    INTO @DEMO_INTELLIGENCE_DB.ANALYTICS.RAW_DATA
    FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/data/
    PATTERN = '.*\.csv';

-- File format
CREATE OR REPLACE FILE FORMAT DEMO_INTELLIGENCE_DB.ANALYTICS.CSV_FORMAT
    TYPE                         = 'CSV'
    SKIP_HEADER                  = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF                      = ('NULL', 'null', '')
    ENCODING                     = 'UTF-8';

-- Load tables from internal stage
COPY INTO PRODUCTS
FROM @DEMO_INTELLIGENCE_DB.ANALYTICS.RAW_DATA/products.csv
FILE_FORMAT = (FORMAT_NAME = 'DEMO_INTELLIGENCE_DB.ANALYTICS.CSV_FORMAT');

COPY INTO SALES
FROM @DEMO_INTELLIGENCE_DB.ANALYTICS.RAW_DATA/sales.csv
FILE_FORMAT = (FORMAT_NAME = 'DEMO_INTELLIGENCE_DB.ANALYTICS.CSV_FORMAT');

COPY INTO CAMPAIGNS
FROM @DEMO_INTELLIGENCE_DB.ANALYTICS.RAW_DATA/campaigns.csv
FILE_FORMAT = (FORMAT_NAME = 'DEMO_INTELLIGENCE_DB.ANALYTICS.CSV_FORMAT');

COPY INTO SUPPORT_CASES
FROM @DEMO_INTELLIGENCE_DB.ANALYTICS.RAW_DATA/support_cases.csv
FILE_FORMAT = (FORMAT_NAME = 'DEMO_INTELLIGENCE_DB.ANALYTICS.CSV_FORMAT');

-- Row count verification
SELECT 'PRODUCTS'      AS table_name, COUNT(*) AS row_count FROM PRODUCTS      UNION ALL
SELECT 'SALES'         AS table_name, COUNT(*) AS row_count FROM SALES          UNION ALL
SELECT 'CAMPAIGNS'     AS table_name, COUNT(*) AS row_count FROM CAMPAIGNS      UNION ALL
SELECT 'SUPPORT_CASES' AS table_name, COUNT(*) AS row_count FROM SUPPORT_CASES;

SELECT '02_data_foundation: done' AS status;
