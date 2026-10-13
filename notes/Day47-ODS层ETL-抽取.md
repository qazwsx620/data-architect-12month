# Day47 · 数仓项目·ODS 层 ETL：抽取（全量/增量 + 原样入库）

> 模块四 · 数仓工程 Day4 | 配套脚本见 `scripts/day47/`（业务模拟数据 + 增量抽取脚本）。
> 背景：订单数仓第一层落地——业务源表 → ODS，原样入库可追溯。
> 虚拟机库：`dw_project`（biz_* 源表 + ods_order 已跑通，9 行）。

---

## 1. 抽取策略：全量 vs 增量

| 策略 | 做法 | 适用 | 缺点 |
|------|------|------|------|
| 全量抽取 | 每次整表全抽 | 数据量小/维表 | 量大后浪费 |
| 增量抽取 | 只抽上次之后新增 | 量大/订单流水 | 需时间戳或日志 |

识别增量两种方式：
- **时间戳**：`WHERE update_time > 上次抽取时间`
- **binlog/日志**：更实时，但复杂

> 面试：小表全量、大表增量；订单流水量大用增量，用户/商品维表小用全量。

## 2. 原样入库原则（ODS 使命）

- 保留原始格式/脏数据，**不加工**（清洗留给 DWD）
- 加两列：`etl_time`（抽取时间）、`raw_data`（原始行兜底）
- 目的：**可追溯**——下游算错，回 ODS 重算

## 3. 增量水位线实现

```python
def get_last_date(cursor):
    """取 ODS 里已有的最大订单日期（增量水位线）"""
    cursor.execute("SELECT COALESCE(MAX(order_date), '1999-01-01') FROM ods_order")
    return cursor.fetchone()[0]
```
- 首次：水位线 1999 → 全量抽
- 之后：只抽 `order_date > 水位线` 的数据

## 4. 核心脚本 ods_extract.py

```python
import pymysql
from config import DW_CONFIG

def get_last_date(cursor):
    cursor.execute("SELECT COALESCE(MAX(order_date), '1999-01-01') FROM ods_order")
    return cursor.fetchone()[0]

def extract_ods():
    conn = pymysql.connect(**DW_CONFIG)
    cursor = conn.cursor()
    last_date = get_last_date(cursor)
    cursor.execute(
        "SELECT order_id, user_id, product_id, amount, status, order_date "
        "FROM biz_order WHERE order_date > %s", (last_date,)
    )
    rows = cursor.fetchall()
    for r in rows:
        order_id, user_id, product_id, amount, status, order_date = r
        raw = f"{order_id},{user_id},{product_id},{amount},{status},{order_date}"
        cursor.execute(
            "INSERT INTO ods_order(order_id,user_id,product_id,amount,status,order_date,etl_time,raw_data) "
            "VALUES(%s,%s,%s,%s,%s,%s,NOW(),%s) "
            "ON DUPLICATE KEY UPDATE raw_data=VALUES(raw_data), etl_time=NOW()",
            (order_id, user_id, product_id, amount, status, order_date, raw)
        )
    conn.commit()
    print(f"增量抽取 {len(rows)} 行（上次截至 {last_date}）")
    conn.close()

if __name__ == "__main__":
    extract_ods()
```

## 5. 运行验证结果

| 操作 | 结果 |
|------|------|
| 第1次运行 | 抽 8 行（水位线 1999 → 首次全量） |
| 第2次运行 | 抽 0 行（水位线 2026-10-12，无新增） |
| 插入 30009（10-13）后 | 抽 1 行（只抽新增） |
| ods_order 总数 | 9 行 ✅ |
| 新行 etl_time/raw_data | 有时间戳 + 原始行 ✅ |

---

## 今日面试考点清单
1. 全量 vs 增量？→ 小表全量大表增量
2. 识别增量方式？→ 时间戳 / binlog
3. ODS 原样入库？→ 可追溯，加 etl_time + raw_data
4. 水位线？→ MAX(order_date)，只抽更大
5. Unknown column 排查？→ DESC 表看结构

## 踩坑记录（面试素材，Day47 现场解决4个）
- `LOAD DATA LOCAL` 报 3948 → `SET GLOBAL local_infile=1;` + 客户端 `--local-infile=1` 重登
- Unknown column 'order_date' → **连错库**（config 指向 test_db，表在 dw_project）
- SQL 里出现字面 %s → execute 第二参数没传（Day42 坑翻版）
- Unknown column 'etl_time' → 表结构缺列，`ALTER TABLE ... ADD COLUMN` 补
