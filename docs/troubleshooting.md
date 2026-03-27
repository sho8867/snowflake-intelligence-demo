# トラブルシューティング

## よくあるエラーと対処方法

---

### 1. `EXECUTE IMMEDIATE FROM` が失敗する

**エラー例**:
```
SQL compilation error: Git repository 'DEMO_REPO' does not exist or not authorized.
```

**原因**: Git Integration のセットアップが未完了、またはリポジトリの最新化が必要。

**対処**:
```sql
-- Git接続DBが存在するか確認
SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS;

-- 存在しない場合は README.md のステップ1を再実行

-- 存在する場合は最新化
ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;
```

---

### 2. `COPY INTO` でデータロードが 0 件になる

**原因**: CSV ファイルが DEMO_REPO ブランチに存在しない、またはパスが異なる。

**対処**:
```sql
-- Git リポジトリ内のファイルを確認
LIST @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/data/;
```

ファイルが表示されない場合:
1. GitHub リポジトリに CSV が push されているか確認
2. `ALTER GIT REPOSITORY ... FETCH;` で最新化

---

### 3. Cortex AI 系のエラー

**エラー例**:
```
Cortex functions are not available in this region.
```

**原因**: Cortex AI が利用できないリージョン。

**対処**: 以下のリージョンで再作成してください（2025年3月時点）:
- AWS: us-east-1, us-west-2, eu-west-1
- Azure: eastus2, westeurope
- GCP: us-central1

最新のサポートリージョンは [Snowflake ドキュメント](https://docs.snowflake.com/en/user-guide/snowflake-cortex/llm-functions#availability) を確認してください。

---

### 4. `CREATE CORTEX AGENT` が失敗する

**エラー例**:
```
SQL compilation error: unknown function CREATE CORTEX AGENT
```

**原因**: Cortex Agent の SQL 構文がアカウントで有効化されていない（Preview 機能）。

**対処**: README.md の「**手動エージェント作成**」セクションに従い、Snowsight UI からエージェントを作成してください。

---

### 5. セマンティックモデルの回答精度が低い

**症状**: 質問に対して的外れなSQLが生成される、またはエラーになる。

**対処**:
1. `assets/semantic_models/demo_sales_model.yaml` の `synonyms` に質問で使っている言葉を追加
2. `verified_queries` に正解SQLを追加
3. 以下で再デプロイ:
   ```sql
   ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;
   EXECUTE IMMEDIATE FROM
     @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/03_deploy_semantic.sql;
   ```

---

### 6. Cortex Search の検索結果が出ない

**症状**: サポートケースの検索で結果が返らない。

**対処**:
```sql
-- サービスのステータスを確認
DESCRIBE CORTEX SEARCH SERVICE DEMO_INTELLIGENCE_DB.ANALYTICS.SUPPORT_SEARCH;
-- INDEXING_STATE が READY になるまで待つ（初回は5〜10分程度）
```

---

### 7. `GRANT OWNERSHIP` でエラーが出る

**エラー例**:
```
Insufficient privileges to operate on database 'DEMO_INTELLIGENCE_DB'
```

**原因**: ACCOUNTADMIN でない、または同名DBが他のロールに所有されている。

**対処**:
```sql
-- teardown で DB を完全削除してから再実行
EXECUTE IMMEDIATE FROM
  @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/99_teardown.sql;
ALTER GIT REPOSITORY SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO FETCH;
EXECUTE IMMEDIATE FROM
  @SNOWFLAKE_QUICKSTART_REPOS.GIT_REPOS.DEMO_REPO/branches/main/assets/sql/00_setup_all.sql;
```

---

## デバッグ用クエリ集

```sql
-- 環境の状態確認
SHOW DATABASES LIKE 'DEMO_INTELLIGENCE_DB';
SHOW WAREHOUSES LIKE 'DEMO_INTELLIGENCE_WH';
SHOW ROLES LIKE 'DEMO_INTELLIGENCE%';
SHOW CORTEX SEARCH SERVICES IN SCHEMA DEMO_INTELLIGENCE_DB.ANALYTICS;

-- データロード確認
SELECT 'PRODUCTS'      AS tbl, COUNT(*) AS cnt FROM DEMO_INTELLIGENCE_DB.ANALYTICS.PRODUCTS      UNION ALL
SELECT 'SALES'         AS tbl, COUNT(*) AS cnt FROM DEMO_INTELLIGENCE_DB.ANALYTICS.SALES          UNION ALL
SELECT 'CAMPAIGNS'     AS tbl, COUNT(*) AS cnt FROM DEMO_INTELLIGENCE_DB.ANALYTICS.CAMPAIGNS      UNION ALL
SELECT 'SUPPORT_CASES' AS tbl, COUNT(*) AS cnt FROM DEMO_INTELLIGENCE_DB.ANALYTICS.SUPPORT_CASES;

-- セマンティックモデルステージ確認
SELECT relative_path, size
FROM DIRECTORY(@DEMO_INTELLIGENCE_DB.ANALYTICS.SEMANTIC_MODELS);
```
