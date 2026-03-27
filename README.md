# Snowflake Intelligence デモ環境

小売業向けの Snowflake Intelligence（自然言語データ問い合わせ）デモ環境です。
**ブラウザだけで**繰り返し構築・破棄できます。ローカルツールのインストールは一切不要です。

## デモ概要

| 項目 | 内容 |
|------|------|
| テーマ | 小売業（売上・商品・マーケティング・サポート） |
| データ | 売上5,200件 / 商品50件 / キャンペーン21件 / サポート300件 |
| 期間 | 2024〜2025年 |
| 機能 | Cortex Analyst（構造化分析）+ Cortex Search（FAQ検索） |

---

## クイックスタート

### 前提条件

- Snowflake アカウント（**Cortex AI 対応リージョン**）
- ACCOUNTADMIN ロールでのログイン
- Cortex AI の動作確認:
  ```sql
  SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large2', 'こんにちは');
  ```

---

### ステップ 1: Git Integration セットアップ（初回のみ）

Snowsight でワークシートを開き、以下を実行してください。
`<org>` と `<repo>` はご自身の GitHub 情報に置き換えてください。

```sql
USE ROLE ACCOUNTADMIN;

-- Git Integration 用の永続 DB
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_QUICKSTART_REPOS
  COMMENT = 'Git Integration 用 - 削除しないでください';
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS;

-- GitHub への HTTPS 接続を許可
CREATE OR REPLACE API INTEGRATION demo_git_api
  API_PROVIDER         = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/<org>/')
  ENABLED              = TRUE;

-- リポジトリ接続
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO
  API_INTEGRATION = demo_git_api
  ORIGIN          = 'https://github.com/<org>/snowflake-intelligence-demo.git';
```

> この手順は初回のみ必要です。2回目以降はステップ 2 だけで再構築できます。

---

### ステップ 2: デモ環境の構築

```sql
-- 最新コードを取得
ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;

-- 全環境を一括構築（3〜10分）
EXECUTE IMMEDIATE FROM
  @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/00_setup_all.sql;
```

---

### ステップ 3: デモ開始

Snowsight の左メニューから **AI & ML > Agents** を開き、`DEMO_SALES_AGENT` を選択します。

以下の質問を試してみてください:

- 「先月の売上はいくらですか？」
- 「カテゴリ別の売上を教えてください」
- 「売上トップ10の商品は？」
- 「関東と関西の売上を比較してください」
- 「SNS広告のCTRとCVRは？」
- 「スマートフォンに関するサポートケースを検索して」

---

## 再構築・クリーンアップ

### クリーンアップ（デモ環境の削除）

```sql
EXECUTE IMMEDIATE FROM
  @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/99_teardown.sql;
```

### 再構築（2回目以降）

```sql
EXECUTE IMMEDIATE FROM
  @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/99_teardown.sql;

ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;

EXECUTE IMMEDIATE FROM
  @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/00_setup_all.sql;
```

---

## 部分的な更新（デモ調整時）

セマンティックモデル YAML のみ更新する場合:

```sql
ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;

EXECUTE IMMEDIATE FROM
  @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/03_deploy_semantic.sql;
```

---

## 手動エージェント作成（05_deploy_agent.sql が失敗した場合）

`CREATE CORTEX AGENT` の SQL 構文が利用できない場合は、Snowsight UI で作成してください。

1. Snowsight > **AI & ML > Agents > Create Agent**
2. **名前**: `DEMO_SALES_AGENT`
3. **説明**: 「小売デモ用エージェント。売上・商品・キャンペーン・サポートに関する質問に自然言語で答えます。」
4. **Tools > Cortex Analyst** を追加し、セマンティックモデルに
   `@DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS/demo_sales_model.yaml` を指定
5. **Tools > Cortex Search** を追加し、`DEMO_INTELLIGENCE_DB.ANALYTICS.SUPPORT_SEARCH` を指定
6. **Example questions** に以下を追加:
   - 先月の売上合計はいくらですか？
   - カテゴリ別の売上ランキングを教えてください
   - 粗利率が最も高い商品は何ですか？
7. **Save**

---

## リポジトリ構成

```
snowflake-intelligence-demo/
├── README.md
├── CLAUDE_CODE_SPEC.md              # Claude Code 向け技術仕様
├── assets/
│   ├── sql/
│   │   ├── 00_setup_all.sql         # エントリポイント
│   │   ├── 01_configure_account.sql # ロール・WH・DB 作成
│   │   ├── 02_data_foundation.sql   # テーブル作成 + CSV ロード
│   │   ├── 03_deploy_semantic.sql   # セマンティックモデル デプロイ
│   │   ├── 04_deploy_cortex_search.sql # Cortex Search 構築
│   │   ├── 05_deploy_agent.sql      # エージェント作成
│   │   └── 99_teardown.sql          # デモ環境の削除
│   ├── data/
│   │   ├── products.csv             # 商品マスタ（50件）
│   │   ├── sales.csv                # 売上トランザクション（5,200件）
│   │   ├── campaigns.csv            # キャンペーン実績（21件）
│   │   └── support_cases.csv        # サポートケース（300件）
│   └── semantic_models/
│       └── demo_sales_model.yaml    # Cortex Analyst セマンティックモデル
└── docs/
    ├── demo_scenario.md             # デモシナリオ・質問リスト
    └── troubleshooting.md           # トラブルシューティング
```

---

## 参考リンク

- [Snowflake Intelligence Getting Started](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-intelligence/)
- [Git Integration 概要](https://docs.snowflake.com/en/developer-guide/git/git-overview)
- [EXECUTE IMMEDIATE FROM](https://docs.snowflake.com/en/sql-reference/sql/execute-immediate-from)
- [Cortex Analyst セマンティックモデル仕様](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/semantic-model-spec)
- [Cortex Search](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview)
