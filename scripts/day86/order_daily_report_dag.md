# 纸面 DAG 设计：order_daily_report（Day86 实操）

> Airflow 第一个 DAG 的纸面设计。目标是跑通"订单数仓日报"，为 Day87 把 etl_chain.py 改造成真实 DAG 打底。

## 需求

订单数仓日报，每天 01:00 自动执行一遍：
1. 抽数：从业务库把昨天的订单抽取出来 → ODS
2. 清洗：清洗规范化后写入明细 → DWD
3. 汇总：按维度轻度汇总 → DWS（供 ADS 报表）

## DAG 定义（结构）

| 项 | 值 |
|----|----|
| dag_id | order_daily_report |
| schedule_interval | 每天 01:00（cron: `0 1 * * *`） |
| start_date | 昨天（调度起始时间） |
| catchup | false（不补跑历史，只从今天起调度） |

## Task 设计

| task_id | Operator | 动作 | 分层 |
|---------|----------|------|------|
| 抽数 | BashOperator | `python extract.py` | → ODS |
| 清洗 | PythonOperator | 函数 `clean` | → DWD |
| 汇总 | BashOperator | `python agg.py` | → DWS |

## 依赖

```
抽数 >> 清洗 >> 汇总
```

语义：抽数成功 → 清洗成功 → 汇总。任一上游失败，下游不执行（依赖阻断）。

## 关键点（对应面试）

- 决定 Task 唯一性的是 `task_id`，不是 Operator 类型（抽数和汇总都是 BashOperator，但 task_id 不同 = 2 个 Task）。
- DAG 必须无环，否则依赖死锁。
- 每次调度周期生成一个 DagRun；Task 实例在 DagRun 内执行，结果写回 Metadata DB。
