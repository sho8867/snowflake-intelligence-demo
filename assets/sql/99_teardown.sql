-- =====================================================
-- Teardown: デモ環境の完全削除
--
-- 注意:
--   - SNOWFLAKE_QUICKSTART_REPOS (Git接続DB) は削除しません
--   - 再構築は README.md の「再構築手順」を参照してください
-- =====================================================

USE ROLE ACCOUNTADMIN;

-- デモ用 DB を削除（テーブル、ステージ、エージェント、サービスをまとめて削除）
DROP DATABASE  IF EXISTS DEMO_INTELLIGENCE_DB;

-- ウェアハウスを削除
DROP WAREHOUSE IF EXISTS DEMO_INTELLIGENCE_WH;

-- ロールを削除
DROP ROLE IF EXISTS DEMO_INTELLIGENCE_USER;
DROP ROLE IF EXISTS DEMO_INTELLIGENCE_ADMIN;

-- Git Integration の権限付与を削除（API Integration 自体は残す）
-- 必要に応じてコメントを外して実行
-- REVOKE USAGE ON DATABASE SNOWFLAKE_QUICKSTART_REPOS FROM ROLE DEMO_INTELLIGENCE_ADMIN;

SELECT 'teardown: デモ環境を削除しました。Git接続 (SNOWFLAKE_QUICKSTART_REPOS) は維持しています。' AS status;
