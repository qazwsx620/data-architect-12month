# Day50 · 数仓项目·ADS 层与报表（ADS SQL + CSV 导出 + HTML 可视化）

> 模块四 · 数仓工程 Day7（加量版：3个实操）| 配套脚本见 `scripts/day50/`（SQL+Python+HTML 三件套）。
> 背景：订单数仓第四层——DWS 轻度汇总 → ADS 业务报表，报表三件套全部跑通。

---

## 1. ADS vs DWS（面试必答）

| | DWS | ADS |
|--|-----|-----|
| 定位 | 通用公共汇总 | 业务专属结果 |
| 粒度 | 细（用户-日/商品-日） | 更聚合（天） |
| 谁用 | 各主题共用 | 特定报表/应用 |
| 例子 | dws_user_daily | ads_gmv_report |

> 一句话：DWS 是"公共中间层"，ADS 是"业务直接要的最终结果"。

## 2. 报表指标口径（延续 Day46）

| 指标 | 口径 |
|------|------|
| GMV | 已支付订单金额合计 |
| 订单量 | 已支付订单笔数 |
| 客单价 | GMV ÷ 订单量（**每笔订单均价**，不是每顾客） |

## 3. 实操① ADS 报表 SQL

```sql
TRUNCATE ads_gmv_report;   -- 幂等重算

INSERT INTO ads_gmv_report (stat_date, gmv, order_cnt, avg_amount)
SELECT stat_date,
       SUM(total_amount) AS gmv,
       SUM(order_cnt)    AS order_cnt,
       ROUND(SUM(total_amount) / SUM(order_cnt), 2) AS avg_amount
FROM dws_user_daily
GROUP BY stat_date;
```

## 4. 实操② CSV 导出（报表下发业务方）

```python
import csv
import pymysql
from config import DW_CONFIG

def export_csv():
    conn = pymysql.connect(**DW_CONFIG)
    cursor = conn.cursor()
    cursor.execute("SELECT stat_date, gmv, order_cnt, avg_amount FROM ads_gmv_report ORDER BY stat_date")
    rows = cursor.fetchall()
    conn.close()
    with open("ads_gmv_report.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["stat_date", "gmv", "order_cnt", "avg_amount"])
        writer.writerows(rows)
    print(f"导出 {len(rows)} 行")
```

## 5. 实操③ HTML 可视化报表（数据汇报）

- 自包含 HTML：GMV 条形图（div 宽度按比例）+ 明细表 + 合计
- 场景：汇报、大屏、直观讲解

## 6. 运行验证结果

| 项目 | 结果 |
|------|------|
| ads_gmv_report | 4 天 ✅（10-10~10-13） |
| 10-10 核对 | GMV=3117（2999+118）、2单、客单价1558.50 ✅ |
| CSV 导出 | 4 行 + 表头 ✅ |
| HTML 报表 | 条形图+表格+合计渲染正确 ✅ |
| 合计核对 | 9973.00 / 6 单 / 1662.17 ✅ |

---

## 今日面试考点清单
1. ADS vs DWS？→ 业务专属结果 vs 通用公共汇总
2. 客单价口径？→ GMV÷订单量（每笔订单均价）
3. 幂等重算？→ TRUNCATE 再插入
4. CSV vs HTML？→ 下发数据 vs 汇报展示
5. 报表指标？→ GMV/订单量/客单价

## 踩坑记录（面试素材）
- 客单价说成"每顾客" → 顾客≠订单，是每笔订单均价
- DWS/ADS 混用 → DWS 通用、ADS 业务专属
- 不幂等重算 → 报表数字翻倍
- 只做 SQL 不做导出 → 报表无法触达业务（三件套完整）
