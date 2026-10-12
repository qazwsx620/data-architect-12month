# Day45 · 数据管道与调度：Airflow 概念（DAG / Task / Operator / 失败处理）

> 模块四 · 数仓工程 Day2 | 配套脚本见 `scripts/day45/` 目录（Airflow DAG 设计）。
> 背景：crontab 只适合单任务，生产数仓需要工作流调度框架（Airflow/DolphinScheduler）。

---

## 1. crontab 的局限（为什么需要调度框架）

| 问题 | crontab | 生产需要 |
|------|---------|----------|
| 多任务依赖 | ❌ 不感知（ODS没跑完DWD也跑了） | 任务按依赖顺序执行 |
| 失败处理 | ❌ 只能靠日志 | 失败自动重试/告警 |
| 监控 | ❌ 无UI | 可视化查看状态 |
| 重跑 | ❌ 手动 | 一键重跑某天/某任务 |
| 跨机器 | ❌ 单机 | 集群调度 |

## 2. DAG（有向无环图）——核心概念

**DAG = 任务节点 + 依赖关系组成的有向无环图，定义工作流执行顺序**。

```
extract_ods → transform_dwd → aggregate_dws → report_ads
```
- **有向**：A → B 表示 B 依赖 A（先 A 后 B）
- **无环**：不能 A→B→A（循环依赖互相等待 → **死锁**）

> 面试：为什么无环？——有环就形成循环依赖，任务互相等对方完成，永远无法结束。

## 3. Airflow 核心概念

| 概念 | 含义 |
|------|------|
| DAG | 整个工作流定义 |
| Task | DAG 里的一个任务节点 |
| Operator | 任务类型（PythonOperator/BashOperator） |
| schedule | 调度周期（cron 表达式） |
| retries / retry_delay | 失败自动重试次数/间隔 |
| 依赖（>>） | task1 >> task2 表示顺序 |

```python
from airflow import DAG
from airflow.operators.python import PythonOperator

with DAG("order_etl_dag", schedule="0 2 * * *") as dag:   # 每天2点
    extract_ods   = PythonOperator(task_id="extract_ods",   python_callable=run_extract)
    transform_dwd = PythonOperator(task_id="transform_dwd", python_callable=run_transform)
    aggregate_dws = PythonOperator(task_id="aggregate_dws", python_callable=run_aggregate)
    report_ads    = PythonOperator(task_id="report_ads",    python_callable=run_report)

    extract_ods >> transform_dwd >> aggregate_dws >> report_ads   # 依赖链
```

## 4. 失败处理链（面试必答）

**重试（retries）→ 告警 → 人工介入**

- `retries=3`：失败自动重试3次，间隔 retry_delay
- retries 用完 → 告警（邮件/钉钉/短信）+ 人工介入
- **下游任务不启动**（依赖未满足，阻断执行，防止脏数据）

## 5. 订单数仓 DAG 设计（本模块项目）

```
每日 02:00：extract_ods → transform_dwd → aggregate_dws → report_ads
失败策略：每任务 retries=3，间隔5分钟；最终失败 → 告警 + 人工介入，下游阻断
```

---

## 今日面试考点清单
1. crontab 局限？→ 依赖/失败/监控/重跑/跨机
2. DAG 是什么？→ 有向无环图，无环防死锁
3. Task/Operator/依赖？→ 节点/执行方式/顺序
4. 失败处理链？→ 重试→告警→人工介入，下游阻断
5. schedule？→ cron 表达式，与 crontab 同语法

## 踩坑记录（面试素材）
- 循环依赖 → 死锁，DAG 必须无环
- 以为 crontab 能编排依赖 → 不感知上下游
- retries 用完还等 → 要告警+人工介入
- 下游不管上游失败直接跑 → 脏数据，必须阻断
- Operator 混淆 → Python 任务用 PythonOperator，shell 用 BashOperator
