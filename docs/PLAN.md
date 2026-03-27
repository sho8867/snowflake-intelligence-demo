# Snowflake Intelligence デモ環境構築 実行計画 v2

## 変更履歴
- v1: 初版（SnowSQL/bash方式、OS依存あり）
- v2: Git Integration + EXECUTE IMMEDIATE FROM 方式に全面改訂
  - ローカルツール不要（ブラウザ完結）
  - OS非依存
  - 公式Quickstart（Telco AI / FSI AI）のパターンを踏襲

---

## 全体像

```
Phase 0: 事前準備         ← 【ユーザー】アカウント作成・Cortex AI確認
Phase 1: スクリプト開発    ← 【Claude Code】GitHubリポジトリの実装
Phase 2: 初回デプロイ      ← 【ユーザー】Snowsightで SQL 実行（コピペ3回）
Phase 3: 動作確認・調整    ← 【ユーザー + Claude Code】デモ確認・YAML調整
Phase 4: 運用準備         ← 【Claude Code】ドキュメント整備・最終パッケージ
```

---

## Phase 0: 事前準備 【ユーザー作業】

| # | 作業 | 詳細 | 完了条件 |
|---|------|------|---------|
| 0-1 | Snowflakeアカウント作成 | トライアル or 既存。**Cortex AI対応リージョン**であること | アカウントURLが確定 |
| 0-2 | ACCOUNTADMIN でログイン確認 | Snowsight にログインし ACCOUNTADMIN が使えることを確認 | ログイン成功 |
| 0-3 | Cortex AI利用可否の確認 | ワークシートで `SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large2', 'hello');` を実行 | レスポンスが返る |
| 0-4 | デモテーマの決定 | 小売 / マーケティング / 金融 等 | テーマ確定 |

> **v1からの変更**: SnowSQL / Snowflake CLI のインストールが不要になった。
> ブラウザでSnowsightにアクセスできれば準備完了。

### ユーザーからClaude Codeへ引き渡す情報
- アカウントURL
- アカウント識別子
- リージョン
- デモテーマ
- 言語要件（日本語/英語）

> **所要時間**: トライアル新規作成の場合 30分〜1時間。既存アカウントなら5分。

---

## Phase 1: スクリプト開発 【Claude Code】

### Step 1-1: GitHubリポジトリの作成

```
実装内容:
  - リポジトリ構成の作成（assets/sql/, assets/data/, assets/semantic_models/）
  - README.md（ユーザー向けセットアップ手順）
  - CLAUDE_CODE_SPEC.md（技術仕様書 — 本ドキュメント）
成果物:
  - GitHubリポジトリの骨格
```

### Step 1-2: デモデータの設計・生成

```
実装内容:
  - テーブルスキーマの定義
  - CSVファイルの作成（数千〜1万行、数MB以下）
  - テーマに合わせた現実的なデータ
制約:
  - GitHubリポジトリに含められるサイズ（個別ファイル100MB以下）
  - COPY INTO で直接読めるCSV形式
成果物:
  - assets/data/*.csv
```

### Step 1-3: SQLスクリプト群の実装

```
実装内容:
  - 01_configure_account.sql（ロール、WH、DB、スキーマ）
  - 02_data_foundation.sql（テーブル作成 + GitリポジトリのCSVからCOPY INTO）
  - 03_deploy_semantic.sql（セマンティックビュー or YAMLデプロイ）
  - 04_deploy_cortex_search.sql（非構造化データ検索）
  - 05_deploy_agent.sql（エージェント作成）
  - 00_setup_all.sql（上記を順次呼び出すエントリポイント）
  - 99_teardown.sql（クリーンアップ）
設計原則:
  - 全SQL冪等（CREATE OR REPLACE / IF NOT EXISTS）
  - 各ファイル先頭で USE ROLE を明示
  - リポジトリパスはフルパスで記述
成果物:
  - assets/sql/*.sql
```

### Step 1-4: セマンティックモデルYAMLの作成

```
実装内容:
  - Step 1-2 のテーブルに対応するYAML作成
  - synonyms に日本語・英語の両方を設定
  - verified_queries を3〜5個（動作するSQL）
  - relationships（複数テーブルの場合）
成果物:
  - assets/semantic_models/demo_sales_model.yaml
```

### Step 1-5: 統合テスト

```
実装内容:
  - 00_setup_all.sql の実行で全ステップがエラーなく通ることを確認
  - 99_teardown.sql → 00_setup_all.sql の再実行で冪等性を確認
  - COPY INTO のファイルパスが正しいことを確認
確認方法:
  - 実際のSnowflakeアカウント（Phase 2と兼用）でテスト
```

> **所要時間**: 2〜4時間

---

## Phase 2: 初回デプロイ 【ユーザー作業】

**v1からの大幅な変更点**: PAT発行や.envファイル作成が不要。
ブラウザでSnowsightを開き、SQLをコピペ実行するだけ。

### Step 2-1: Git Integration セットアップ 【ユーザー — 1回のみ】

Snowsightでワークシートを開き、READMEに記載された以下のSQLを実行。

```sql
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_QUICKSTART_REPOS
  COMMENT = 'Git Integration用 - 削除しないでください';
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS;

CREATE OR REPLACE API INTEGRATION demo_git_api
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/<org>/')
  ENABLED = TRUE;

CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO
  API_INTEGRATION = demo_git_api
  ORIGIN = 'https://github.com/<org>/snowflake-intelligence-demo.git';
```

> 所要時間: 2分（SQLコピペ実行）

### Step 2-2: デモ環境構築 【ユーザー】

```sql
ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;

EXECUTE IMMEDIATE FROM
  @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/00_setup_all.sql;
```

> 所要時間: 3〜10分（SQL実行時間。データ量とCortex Searchのインデックス構築による）

### Step 2-3: エージェント設定（手動が必要な場合のみ） 【ユーザー】

05_deploy_agent.sql でエージェントが自動作成できない場合:

```
1. Snowsight > AI & ML > Agents > Create Agent
2. 名前: Demo_Sales_Agent
3. 説明: README記載のテンプレートをコピペ
4. Tools > Cortex Analyst > セマンティックビュー / YAMLを選択
5. Example questions: README記載の質問をコピペ
6. Save
```

> 所要時間: 5分（手動操作）

### Step 2-4: デモ動作確認 【ユーザー】

Snowsight > AI & ML > Agents からエージェントを選択し、質問を投げる。

> **Phase 2 合計所要時間: 10〜20分**（v1の30分〜1時間から大幅短縮）

---

## Phase 3: 動作確認・調整 【ユーザー + Claude Code】

### Step 3-1: 基本動作確認 【ユーザー】

以下の質問で動作確認:
1. 「先月の売上合計はいくら？」 → 単純集計
2. 「カテゴリ別の売上を教えて」 → GROUP BY
3. 「売上トップ10の商品は？」 → ORDER BY + LIMIT
4. 「月次の売上推移をグラフで見せて」 → チャート生成
5. 「前年比で売上が下がったカテゴリは？」 → 複雑SQL

### Step 3-2: 問題修正サイクル 【ユーザー → Claude Code】

```
1. ユーザーが問題点をClaude Codeに共有
2. Claude Code がGitHub上のSQL/YAMLを修正・push
3. ユーザーが以下を実行して反映:

   -- 最新取得
   ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;
   -- 必要に応じて再デプロイ（セマンティックモデルのみ等）
   EXECUTE IMMEDIATE FROM
     @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/03_deploy_semantic.sql;

4. ユーザーが再確認
```

> **v1からの改善**: GitHub push → Snowflakeで FETCH → 該当SQLだけ再実行。
> スクリプト全体を再実行する必要はなく、変更箇所のSQLファイルだけを指定できる。

### Step 3-3: デモシナリオ確定 【ユーザー + Claude Code】

成果物: docs/demo_scenario.md

> **所要時間**: 1〜3時間

---

## Phase 4: 運用準備 【Claude Code】

### Step 4-1: ドキュメント整備
- README.md 完成版
- docs/troubleshooting.md
- docs/demo_scenario.md

### Step 4-2: 再利用性の向上
- 環境名プレフィックスのパラメータ化（Jinja変数、将来対応）
- デモテーマ切り替え機構の検討

### Step 4-3: 最終パッケージング
- .gitignore 整備
- 全SQLファイルの最終テスト

> **所要時間**: 1〜2時間

---

## タイムライン概要

```
Day 1
  ┣━ Phase 0 [ユーザー]       アカウント確認 ..................... 5分〜1時間
  ┃    ↓ アカウント情報をClaude Codeに共有
  ┣━ Phase 1 [Claude Code]    スクリプト開発 .................. 2〜4時間
  ┃    ↓ GitHubリポジトリ完成
  ┣━ Phase 2 [ユーザー]       SQLコピペ実行 ................... 10〜20分 ★大幅短縮
  ┃    ↓ デプロイ完了
  ┗━ Phase 3 [ユーザー+CC]    動作確認・調整 .................. 1〜3時間

Day 2（必要な場合）
  ┣━ Phase 3 続き             追加調整 ....................... 必要に応じて
  ┗━ Phase 4 [Claude Code]    ドキュメント・パッケージ ........ 1〜2時間
```

**最短ケース: 半日で完了（3〜5時間）**
**標準ケース: 1日（調整の反復を含む）**

---

## ユーザー介在ポイントまとめ

| タイミング | 作業内容 | 所要時間 | v1との比較 |
|-----------|---------|---------|-----------|
| Phase 0 | アカウント確認 | 5分〜1時間 | CLIインストール不要に |
| Phase 0→1 | アカウント情報共有 | 5分 | 変更なし |
| Phase 2-1 | Git Integration SQL コピペ実行（初回のみ） | 2分 | **PAT発行・.env作成が不要に** |
| Phase 2-2 | EXECUTE IMMEDIATE FROM 実行 | 3〜10分 | **bash実行→SQL1行に** |
| Phase 2-3 | エージェントUI設定（必要な場合のみ） | 5分 | 変更なし |
| Phase 3 | デモ動作確認 | 30分〜2時間 | 変更なし |
| Phase 3 | FETCH + 再実行（修正反映時） | 1分 | **git pull → SQL1行に** |

---

## 2回目以降の環境構築（運用時）

```sql
-- 前回環境を削除
EXECUTE IMMEDIATE FROM
  @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/99_teardown.sql;

-- 最新コードを取得
ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;

-- 再構築
EXECUTE IMMEDIATE FROM
  @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/00_setup_all.sql;
```

**ユーザー操作: SQL 3行をコピペ実行。所要時間: 5〜10分。**

---

## v1 → v2 の主な変更点まとめ

| 項目 | v1 (bash + SnowSQL) | v2 (Git Integration) |
|------|---------------------|---------------------|
| 前提ツール | SnowSQL or Snowflake CLI | なし（ブラウザのみ） |
| OS依存 | bash 前提（Windows は WSL 必要） | OS 無関係 |
| 認証方式 | PAT 発行 + .env ファイル作成 | 不要（Snowsight ログインのみ） |
| デプロイ操作 | `bash scripts/setup.sh` | SQL 1行 (`EXECUTE IMMEDIATE FROM`) |
| データロード | PUT コマンド（SnowSQL経由） | COPY INTO（Gitリポジトリから直接） |
| スクリプト更新反映 | `git pull` + `bash setup.sh` | `ALTER ... FETCH` + `EXECUTE IMMEDIATE FROM` |
| 部分再デプロイ | スクリプト全体を再実行 | 変更したSQLファイルだけ指定実行 |
| 外部サービス | なし | GitHub（Public Repo、無料） |
| 参考実装 | なし | Snowflake公式 Telco AI / FSI AI Quickstart |
