"""デモ用CSVデータ生成スクリプト"""
import csv
import random
from datetime import date, timedelta

random.seed(42)

# ============================================================
# マスタデータ定義
# ============================================================
CATEGORIES = ["家電", "衣料品", "食品", "スポーツ", "美容・健康"]
SUBCATEGORIES = {
    "家電":     ["スマートフォン", "タブレット", "ノートPC", "イヤホン", "スマートウォッチ"],
    "衣料品":   ["メンズトップス", "レディーストップス", "ボトムス", "アウター", "シューズ"],
    "食品":     ["スナック菓子", "飲料", "健康食品", "インスタント食品", "調味料"],
    "スポーツ": ["フィットネス用品", "アウトドア", "ランニング", "チームスポーツ", "水泳"],
    "美容・健康": ["スキンケア", "ヘアケア", "サプリメント", "メイクアップ", "フレグランス"],
}
REGIONS = ["関東", "関西", "東海", "九州", "東北", "北海道", "中国・四国"]
STORES = {
    "関東":   ["S001", "S002", "S003", "S004"],
    "関西":   ["S005", "S006", "S007"],
    "東海":   ["S008", "S009"],
    "九州":   ["S010", "S011"],
    "東北":   ["S012", "S013"],
    "北海道": ["S014"],
    "中国・四国": ["S015", "S016"],
}

# ============================================================
# 商品マスタ (products.csv) — 60商品
# ============================================================
products = []
pid = 1
for cat, subs in SUBCATEGORIES.items():
    for sub in subs:
        for i in range(1, 3):  # 各サブカテゴリ2商品
            base_price = {
                "家電": random.randint(8000, 120000),
                "衣料品": random.randint(2000, 25000),
                "食品": random.randint(200, 2000),
                "スポーツ": random.randint(1500, 40000),
                "美容・健康": random.randint(800, 15000),
            }[cat]
            cost_ratio = random.uniform(0.4, 0.65)
            products.append({
                "product_id": f"P{pid:04d}",
                "product_name": f"{sub} {['プレミアム', 'スタンダード', 'エコノミー', 'プロ', 'ライト'][i-1]}",
                "category": cat,
                "subcategory": sub,
                "unit_price": round(base_price, -2),
                "cost_price": round(base_price * cost_ratio, -2),
            })
            pid += 1

with open("products.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=products[0].keys())
    w.writeheader()
    w.writerows(products)
print(f"products.csv: {len(products)} rows")

# ============================================================
# 売上トランザクション (sales.csv) — ~5000行
# ============================================================
product_map = {p["product_id"]: p for p in products}
product_ids = [p["product_id"] for p in products]

start_date = date(2024, 1, 1)
end_date = date(2025, 12, 31)
total_days = (end_date - start_date).days

sales = []
sale_id = 1

# 季節変動係数
def season_factor(d):
    m = d.month
    if m in [12, 1]:  return 1.6  # 年末年始
    if m in [7, 8]:   return 1.3  # 夏
    if m in [3, 4]:   return 1.2  # 春（新生活）
    if m in [10, 11]: return 1.2  # 秋（ボーナス）
    return 1.0

for _ in range(5200):
    d = start_date + timedelta(days=random.randint(0, total_days))
    pid = random.choice(product_ids)
    p = product_map[pid]
    region = random.choice(REGIONS)
    store = random.choice(STORES[region])
    units = max(1, int(random.gauss(3, 2) * season_factor(d)))
    price = p["unit_price"] * random.uniform(0.9, 1.05)  # 値引き・プレミアム
    sales.append({
        "sale_id": f"TRX{sale_id:06d}",
        "sale_date": d.isoformat(),
        "product_id": pid,
        "product_name": p["product_name"],
        "category": p["category"],
        "subcategory": p["subcategory"],
        "region": region,
        "store_id": store,
        "units_sold": units,
        "revenue": round(price * units, 2),
        "cost": round(p["cost_price"] * units, 2),
    })
    sale_id += 1

sales.sort(key=lambda x: x["sale_date"])

with open("sales.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=sales[0].keys())
    w.writeheader()
    w.writerows(sales)
print(f"sales.csv: {len(sales)} rows")

# ============================================================
# キャンペーン (campaigns.csv) — 40件
# ============================================================
CHANNELS = ["SNS広告", "メールマーケティング", "テレビCM", "雑誌広告", "検索広告", "店頭プロモーション"]
campaigns = []
cid = 1
for year in [2024, 2025]:
    for month in range(1, 13):
        if month % 3 != 0 and random.random() < 0.3:
            continue
        cat = random.choice(CATEGORIES)
        channel = random.choice(CHANNELS)
        budget = random.choice([500000, 800000, 1000000, 1500000, 2000000, 3000000])
        spend_ratio = random.uniform(0.75, 1.05)
        impressions = int(budget / random.uniform(5, 15))
        ctr = random.uniform(0.02, 0.08)
        cvr = random.uniform(0.03, 0.12)
        clicks = int(impressions * ctr)
        conversions = int(clicks * cvr)
        start = date(year, month, random.randint(1, 10))
        end = start + timedelta(days=random.randint(14, 45))
        campaigns.append({
            "campaign_id": f"CMP{cid:04d}",
            "campaign_name": f"{year}年{month}月 {cat} {channel}キャンペーン",
            "category": cat,
            "channel": channel,
            "start_date": start.isoformat(),
            "end_date": end.isoformat(),
            "budget": budget,
            "actual_spend": round(budget * spend_ratio, 0),
            "impressions": impressions,
            "clicks": clicks,
            "conversions": conversions,
        })
        cid += 1

with open("campaigns.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=campaigns[0].keys())
    w.writeheader()
    w.writerows(campaigns)
print(f"campaigns.csv: {len(campaigns)} rows")

# ============================================================
# サポートケース (support_cases.csv) — 300件（Cortex Search用）
# ============================================================
PRIORITIES = ["高", "中", "低"]
STATUSES = ["解決済み", "対応中", "未対応"]
TRANSCRIPTS = [
    ("家電", "スマートフォンの画面が突然暗くなってしまいます。充電は十分あるのですが、何度か電源を入れ直しても改善しません。購入から3ヶ月ほど経ちます。"),
    ("家電", "イヤホンを接続してもBluetoothがすぐに切れてしまいます。他のデバイスでは問題ないため、製品の不具合ではないかと疑っています。"),
    ("家電", "ノートPCのバッテリーが急速に消耗します。フル充電から2時間程度しか持ちません。購入時は8時間以上持つとのことでした。"),
    ("衣料品", "サイズ交換をお願いしたいです。Mサイズを購入しましたが、着用してみると少し小さく感じます。Lサイズと交換可能でしょうか。"),
    ("衣料品", "洗濯後に縮んでしまいました。洗濯表示通りに洗ったつもりですが、1サイズ小さくなった感覚があります。返品対応は可能ですか？"),
    ("食品", "賞味期限が記載された日より前に開封したところ、異臭がしました。品質管理の問題があるのではないでしょうか。"),
    ("食品", "アレルギー表示について確認したいです。購入した商品の成分表に小麦が含まれているか明記されていませんでした。"),
    ("スポーツ", "ランニングシューズのソールが剥がれてきました。購入から6ヶ月ですが、週に3回程度使用しています。保証対応はありますか？"),
    ("スポーツ", "フィットネス器具の組み立て説明書が不明確で、正しく組み立てられているか不安です。動画での説明はありますか？"),
    ("美容・健康", "スキンケア商品を使用後に肌が赤くなってしまいました。敏感肌用とのことでしたが、刺激が強いようです。返品できますか？"),
    ("美容・健康", "サプリメントの服用方法について教えてください。食前と食後のどちらが効果的でしょうか？"),
    ("家電", "スマートウォッチのGPS機能が正確に動作しません。ランニング中に計測した距離が実際より短く表示されます。"),
    ("衣料品", "カラーが写真と違います。モニターの問題かもしれませんが、実物はかなり暗い色調でイメージと異なりました。"),
    ("食品", "定期購入の解約方法を教えてください。マイページから操作しても解約できないエラーが発生します。"),
    ("スポーツ", "アウトドアグッズの防水性能について確認したいです。小雨程度は問題ないとのことでしたが、先日の使用で濡れてしまいました。"),
]

support_cases = []
for i in range(1, 301):
    d = start_date + timedelta(days=random.randint(0, total_days))
    t = random.choice(TRANSCRIPTS)
    cat = t[0]
    transcript = t[1]
    # 対応履歴を付加
    responses = [
        f"【{d.isoformat()} 受付】{transcript}",
        f"【対応記録】担当者がお客様に連絡を取り、状況を詳しく確認しました。",
    ]
    status = random.choice(STATUSES)
    if status == "解決済み":
        responses.append("【解決】お客様のご要望に応じた対応を完了しました。ご不便をおかけしました。")
    full_transcript = " / ".join(responses)
    support_cases.append({
        "case_id": f"CASE{i:05d}",
        "created_date": d.isoformat(),
        "category": cat,
        "priority": random.choice(PRIORITIES),
        "transcript": full_transcript,
        "resolution_status": status,
    })

support_cases.sort(key=lambda x: x["created_date"])

with open("support_cases.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=support_cases[0].keys())
    w.writeheader()
    w.writerows(support_cases)
print(f"support_cases.csv: {len(support_cases)} rows")
