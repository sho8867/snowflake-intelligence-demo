# Snowflake Intelligence デモ環境 自動構築 技術仕様書 v2

## 変更履歴
- v1: 初版（SnowSQL/bash方式）
- v2: Git Integration + EXECUTE IMMEDIATE FROM 方式に全面改訂

---

## 1. プロジェクト概要

### ゴール
Snowflake Intelligence（自然言語によるデータ問い合わせ）のデモ環境を、
**ブラウザ（Snowsight）だけで繰り返し構築できる**自動化リポジトリを作成する。

### 設計原則
- **OS非依存**: SnowSQL, Python, Terraform 等のローカルツール一切不要
- **ブラウザ完結**: Snowsight のワークシートからSQLを実行するだけ
- **1行実行**: Git Integration初回セットアップ後は `EXECUTE IMMEDIATE FROM` 1行で全構築
- **冪等設計**: 何度実行してもエラーにならない（CREATE OR REPLACE / IF NOT EXISTS）
- **分離設計**: Git接続用DBとデモ用DBを分離し、デモ環境のDROP/再構築を安全に繰り返せる

### 前提条件
- Snowflakeアカウント（Cortex AI対応リージョン）
- ACCOUNTADMIN ロールでのログイン
- ブラウザ（Snowsight にアクセスできること）

---

## 2. アーキテクチャ

### デプロイフロー

```
┌─────────────────────────────────────────────────────────┐
│  GitHub (Public Repository)                              │
│  snowflake-intelligence-demo/                            │
│  ├── assets/                                             │
│  │   ├── sql/                                            │
│  │   │   ├── 00_setup_all.sql    ← エントリポイント       │
│  │   │   ├── 01_configure_account.sql                    │
│  │   │   ├── 02_data_foundation.sql                      │
│  │   │   ├── 03_deploy_semantic.sql                      │
│  │   │   ├── 04_deploy_cortex_search.sql                 │
│  │   │   ├── 05_deploy_agent.sql                         │
│  │   │   └── 99_teardown.sql                             │
│  │   ├── data/                                           │
│  │   │   ├── products.csv                                │
│  │   │   ├── sales.csv                                   │
│  │   │   └── support_cases.csv                           │
│  │   └── semantic_models/                                │
│  │       └── demo_model.yaml                             │
│  └── README.md                                           │
└────────────────────────┬────────────────────────────────┘
                         │ HTTPS (読み取り)
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Snowflake アカウント                                     │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │ SNOWFLAKE_QUICKSTART_REPOS (永続DB)               │    │
│  │  └── GIT_REPOS スキーマ                            │    │
│  │       └── DEMO_REPO (Git Repository オブジェクト)   │    │
│  └──────────────────────────────────────────────────┘    │
│         │ EXECUTE IMMEDIATE FROM                         │
│         ▼                                                │
│  ┌──────────────────────────────────────────────────┐    │
│  │ DEMO_INTELLIGENCE_DB (デモ用DB — DROP/再作成可能)   │    │
│  │  ├── テーブル & データ                              │    │
│  │  ├── セマンティックビュー / YAML                     │    │
│  │  ├── Cortex Search サービス                         │    │
│  │  └── エージェント                                   │    │
│  └──────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### DB分離設計（公式Quickstartのパターンを踏襲）

| DB名 | 用途 | ライフサイクル |
|------|------|-------------|
| SNOWFLAKE_QUICKSTART_REPOS | Git Integration 接続情報を保持 | 永続（削除しない） |
| DEMO_INTELLIGENCE_DB | デモ環境本体（テーブル、モデル等） | 使い捨て（何度でもDROP/再作成） |

この分離により、デモ環境を破棄してもGit接続が維持され、再構築は `FETCH` + `EXECUTE IMMEDIATE FROM` の2行で完了する。

---

## 3. 利用するサービスとコンポーネント

### Snowflake 内部オブジェクト

| オブジェクト | 用途 | 作成タイミング |
|------------|------|-------------|
| API Integration | GitHub への HTTPS 通信を許可 | 初回セットアップ時（1回のみ） |
| Git Repository | リモートリポジトリのローカルクローン | 初回セットアップ時（1回のみ） |
| ロール | DEMO_INTELLIGENCE_ADMIN, DEMO_INTELLIGENCE_USER | 01_configure_account.sql |
| ウェアハウス | DEMO_INTELLIGENCE_WH (XSMALL, AUTO_SUSPEND=60) | 01_configure_account.sql |
| データベース | DEMO_INTELLIGENCE_DB | 01_configure_account.sql |
| テーブル | 商品、売上、サポートケース等 | 02_data_foundation.sql |
| セマンティックビュー or YAML | Cortex Analyst 用のデータモデル定義 | 03_deploy_semantic.sql |
| Cortex Search サービス | 非構造化データの検索インデックス | 04_deploy_cortex_search.sql |
| エージェント | Intelligence の本体 | 05_deploy_agent.sql |

### 外部サービス

| サービス | 用途 | コスト |
|---------|------|--------|
| GitHub | SQLファイル・CSVデータ・YAMLのホスティング | 無料（Public Repo） |

### 費用

| 項目 | 概算 |
|------|------|
| Git Integration 自体 | 無料（専用課金なし） |
| セットアップSQL実行 (XSMALL WH, 5分) | ≒0.08 credits ($0.16) |
| Cortex Search Service (1時間) | 数credits |
| Cortex AI Functions (デモ使用) | トークンベース、数credits |
| ストレージ (デモデータ数MB) | 無視できるレベル |
| **トライアルアカウント ($400無料) で十分** | |

---

## 4. リポジトリ構成

```
snowflake-intelligence-demo/
├── README.md                              # セットアップ手順（ユーザー向け）
├── CLAUDE_CODE_SPEC.md                    # Claude Code向け実装仕様
├── assets/
│   ├── sql/
│   │   ├── 00_setup_all.sql               # エントリポイント（他のSQLを順次呼び出す）
│   │   ├── 01_configure_account.sql       # ロール、WH、DB、スキーマ作成
│   │   ├── 02_data_foundation.sql         # テーブル作成 & CSVロード
│   │   ├── 03_deploy_semantic.sql         # セマンティックビュー or YAML デプロイ
│   │   ├── 04_deploy_cortex_search.sql    # Cortex Search サービス作成
│   │   ├── 05_deploy_agent.sql            # エージェント作成
│   │   └── 99_teardown.sql               # デモ環境の完全削除
│   ├── data/
│   │   ├── products.csv                   # 商品マスタ
│   │   ├── sales.csv                      # 売上トランザクション
│   │   ├── campaigns.csv                  # マーケティングキャンペーン
│   │   └── support_cases.csv             # サポートケース（非構造化データ）
│   └── semantic_models/
│       └── demo_sales_model.yaml          # セマンティックモデル定義
└── docs/
    ├── demo_scenario.md                   # デモシナリオ・質問リスト
    └── troubleshooting.md                 # トラブルシューティング
```

---

## 5. 各SQLファイルの実装仕様

### 00_setup_all.sql（エントリポイント）

```sql
-- =====================================================
-- Snowflake Intelligence Demo - Setup All
-- このファイル1つで全環境が構築される
-- =====================================================

-- リポジトリパスの変数定義
SET repo_path = '@SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql';

EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/01_configure_account.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/02_data_foundation.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/03_deploy_semantic.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/04_deploy_cortex_search.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/05_deploy_agent.sql;
```

### 01_configure_account.sql（インフラ構築）

```sql
USE ROLE ACCOUNTADMIN;

-- ロール
CREATE ROLE IF NOT EXISTS DEMO_INTELLIGENCE_ADMIN;
CREATE ROLE IF NOT EXISTS DEMO_INTELLIGENCE_USER;
GRANT ROLE DEMO_INTELLIGENCE_ADMIN TO ROLE ACCOUNTADMIN;
GRANT ROLE DEMO_INTELLIGENCE_USER TO ROLE DEMO_INTELLIGENCE_ADMIN;

-- Cortex AI 権限
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DEMO_INTELLIGENCE_ADMIN;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DEMO_INTELLIGENCE_USER;

-- ウェアハウス
CREATE WAREHOUSE IF NOT EXISTS DEMO_INTELLIGENCE_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;
GRANT USAGE ON WAREHOUSE DEMO_INTELLIGENCE_WH TO ROLE DEMO_INTELLIGENCE_ADMIN;
GRANT USAGE ON WAREHOUSE DEMO_INTELLIGENCE_WH TO ROLE DEMO_INTELLIGENCE_USER;

-- データベース & スキーマ
CREATE OR REPLACE DATABASE DEMO_INTELLIGENCE_DB;
CREATE OR REPLACE SCHEMA DEMO_INTELLIGENCE_DB.ANALYTICS;

GRANT OWNERSHIP ON DATABASE DEMO_INTELLIGENCE_DB TO ROLE DEMO_INTELLIGENCE_ADMIN
  COPY CURRENT GRANTS;
GRANT USAGE ON DATABASE DEMO_INTELLIGENCE_DB TO ROLE DEMO_INTELLIGENCE_USER;
GRANT USAGE ON SCHEMA DEMO_INTELLIGENCE_DB.ANALYTICS TO ROLE DEMO_INTELLIGENCE_USER;
GRANT SELECT ON ALL TABLES IN SCHEMA DEMO_INTELLIGENCE_DB.ANALYTICS TO ROLE DEMO_INTELLIGENCE_USER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA DEMO_INTELLIGENCE_DB.ANALYTICS TO ROLE DEMO_INTELLIGENCE_USER;
```

### 02_data_foundation.sql（テーブル & データロード）

```sql
USE ROLE DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;
USE DATABASE DEMO_INTELLIGENCE_DB;
USE SCHEMA ANALYTICS;

-- テーブル定義
CREATE OR REPLACE TABLE PRODUCT_SALES (
    date DATE,
    product_id VARCHAR(20),
    product_name VARCHAR(100),
    category VARCHAR(50),
    region VARCHAR(50),
    units_sold NUMBER,
    revenue NUMBER(12,2),
    cost NUMBER(12,2)
);

-- Git リポジトリ内のCSVから直接ロード
COPY INTO PRODUCT_SALES
FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/data/sales.csv
FILE_FORMAT = (
    TYPE = 'CSV'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '')
);

-- 追加テーブル（products, campaigns, support_cases）も同様のパターンで作成
-- ...
```

### 03_deploy_semantic.sql（セマンティックモデル）

2つの方式を検討し、実装時に安定する方を選択:

**方式A: セマンティックビュー（SQL DDL）— 推奨**
```sql
CREATE OR REPLACE SEMANTIC VIEW DEMO_INTELLIGENCE_DB.ANALYTICS.SALES_SEMANTIC_VIEW
  -- DDL仕様はSnowflakeバージョンに依存
  -- https://docs.snowflake.com/en/sql-reference/sql/create-semantic-view
;
```

**方式B: YAMLファイルをステージ経由でデプロイ**
```sql
-- Gitリポジトリ内のYAMLを内部ステージにコピーしてデプロイ
CREATE STAGE IF NOT EXISTS DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS
  DIRECTORY = (ENABLE = TRUE);

-- Git repo → 内部ステージへコピー
COPY FILES
  INTO @DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS
  FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/semantic_models/
  PATTERN = '.*\.yaml';

-- YAML → Semantic View 変換（利用可能な場合）
-- CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(...);
```

### 04_deploy_cortex_search.sql（非構造化データ検索）

```sql
USE ROLE DEMO_INTELLIGENCE_ADMIN;
USE WAREHOUSE DEMO_INTELLIGENCE_WH;

CREATE OR REPLACE CORTEX SEARCH SERVICE
  DEMO_INTELLIGENCE_DB.ANALYTICS.SUPPORT_SEARCH
  ON support_cases
  WAREHOUSE = DEMO_INTELLIGENCE_WH
  TARGET_LAG = '1 hour'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
  AS (
    SELECT case_id, transcript, category, created_date
    FROM DEMO_INTELLIGENCE_DB.ANALYTICS.SUPPORT_CASES
  );
```

### 05_deploy_agent.sql（エージェント作成）

SQL での CREATE AGENT が利用可能かを確認し実装。
REST API が必要な場合はストアドプロシージャ経由で呼び出す。

```sql
-- 方式1: SQL（GA版で利用可能な場合）
-- CREATE OR REPLACE AGENT ...

-- 方式2: REST API をストアドプロシージャから呼び出し
-- CREATE OR REPLACE PROCEDURE deploy_agent()
-- RETURNS STRING
-- LANGUAGE PYTHON
-- ...

-- 方式3: フォールバック（手動案内）
-- エージェント作成はSnowsight UIで実施
-- 手順は README.md の「手動ステップ」セクションを参照
```

### 99_teardown.sql（クリーンアップ）

```sql
USE ROLE ACCOUNTADMIN;

-- デモ環境を削除（Git接続は残す）
DROP DATABASE IF EXISTS DEMO_INTELLIGENCE_DB;
DROP WAREHOUSE IF EXISTS DEMO_INTELLIGENCE_WH;
DROP ROLE IF EXISTS DEMO_INTELLIGENCE_USER;
DROP ROLE IF EXISTS DEMO_INTELLIGENCE_ADMIN;

-- 注意: SNOWFLAKE_QUICKSTART_REPOS は削除しない（Git接続を維持するため）
```

---

## 6. セマンティックモデル YAML 仕様

（v1から変更なし — synonymsに日本語を含める、verified_queriesは3〜5個、
base_tableは完全修飾名で記述、の原則は維持）

---

## 7. README.md に記載するユーザー向け手順

```markdown
## クイックスタート（5分）

### ステップ1: Git Integration セットアップ
Snowsight でワークシートを開き、以下のSQLを実行してください。

（※ この手順は初回のみです。2回目以降はステップ2だけで構築できます。）

    USE ROLE ACCOUNTADMIN;

    -- Git Integration 用の永続DB作成
    CREATE DATABASE IF NOT EXISTS SNOWFLAKE_QUICKSTART_REPOS
      COMMENT = 'Git Integration 用 - 削除しないでください';
    CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS;

    -- GitHub への API 接続許可
    CREATE OR REPLACE API INTEGRATION demo_git_api
      API_PROVIDER = git_https_api
      API_ALLOWED_PREFIXES = ('https://github.com/<org>/')
      ENABLED = TRUE;

    -- Git リポジトリ接続
    CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO
      API_INTEGRATION = demo_git_api
      ORIGIN = 'https://github.com/<org>/snowflake-intelligence-demo.git';

### ステップ2: デモ環境構築
以下の2行を実行するだけです。

    ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;

    EXECUTE IMMEDIATE FROM
      @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/00_setup_all.sql;

### ステップ3: デモ開始
Snowsight > AI & ML > Agents からエージェントを選択してデモを開始してください。

### クリーンアップ

    EXECUTE IMMEDIATE FROM
      @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/99_teardown.sql;

### 再構築（2回目以降）

    -- クリーンアップ → 再構築
    EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/99_teardown.sql;
    ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;
    EXECUTE IMMEDIATE FROM @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/00_setup_all.sql;
```

---

## 8. 実装時の注意事項（Claude Code向け）

1. **SQLは全て冪等に**: CREATE OR REPLACE / IF NOT EXISTS を徹底
2. **ロール切り替えを明示**: 各SQLファイルの先頭で USE ROLE を必ず記述
3. **リポジトリパスはフルパスで**: `@SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/...` を省略しない
4. **CSVはGitリポジトリ内に同梱**: COPY INTO で `@...DEMO_REPO/branches/main/assets/data/xxx.csv` から直接ロード
5. **YAMLもGitリポジトリ内に同梱**: COPY FILES で内部ステージへコピーしてからCortex Analystに読ませる
6. **Git用DBとデモ用DBは分離**: SNOWFLAKE_QUICKSTART_REPOS は teardown で削除しない
7. **verified_queries のSQLは事前テスト**: テーブル名・カラム名の不一致がないことを確認
8. **synonyms に日本語・英語の両方**: デモの言語に合わせて設定
9. **エージェント作成部分は最後に実装**: SQL / REST API / UI手動のいずれになるか要検証
10. **デモデータは数千〜1万行程度**: Gitリポジトリに含められるCSVサイズ（数MB以下）に収める

---

## 9. 参照リンク

### 公式ドキュメント（Git Integration）
- Git Integration 概要: https://docs.snowflake.com/en/developer-guide/git/git-overview
- セットアップ手順: https://docs.snowflake.com/en/developer-guide/git/git-setting-up
- 操作方法: https://docs.snowflake.com/en/developer-guide/git/git-operations
- 使用例: https://docs.snowflake.com/en/developer-guide/git/git-examples
- 制限事項: https://docs.snowflake.com/en/developer-guide/git/git-limitations
- EXECUTE IMMEDIATE FROM: https://docs.snowflake.com/en/sql-reference/sql/execute-immediate-from

### 公式Quickstart（同パターンの実装例）
- Telco AI Assistant: https://www.snowflake.com/en/developers/guides/build-an-ai-assistant-for-telco-with-aisql-and-snowflake-intelligence/
  - GitHub: https://github.com/Snowflake-Labs/sfguide-build-an-ai-assistant-for-telco-with-aisql-and-snowflake-intelligence
- FSI AI Assistant: https://www.snowflake.com/en/developers/guides/build-an-ai-assistant-for-fsi-with-aisql-and-snowflake-intelligence/
  - GitHub: https://github.com/Snowflake-Labs/sfguide-Build-an-AI-Assistant-for-FSI-with-AISQL-and-Snowflake-Intelligence

### Snowflake Intelligence / Cortex AI
- Intelligence Quickstart: https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-intelligence/
- Cortex Agents Quickstart: https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/
- セマンティックビュー概要: https://docs.snowflake.com/en/user-guide/views-semantic/overview
- エージェント管理: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-manage
