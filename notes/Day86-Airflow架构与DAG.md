# Day86 Airflow 架构与 DAG（模块七：数据平台工程）

> 实际进度：Day86（模块七第 1 天）。计划表编号已对齐，Day86 = Airflow 架构与 DAG。
> 主题：从"crontab 手写调度"升级为"Airflow 任务编排平台"，掌握架构组件、核心循环、三大抽象，并纸面落地第一个 DAG。

---

## 1. 为什么需要 Airflow：crontab 四大局限

| # | crontab 局限 | 后果 |
|---|--------------|------|
| 1 | **只认"到点执行"，不认任务间依赖** | 上游没跑完，下游照跑，数据脏 |
| 2 | **失败不自动重试** | 挂了就是挂了，靠脚本自己判断，易漏 |
| 3 | **执行历史/日志无可视化** | 只能自己去日志文件里翻，排查慢 |
| 4 | **一行一条 crontab，多个任务=多个散落配置** | 无法编排、无法管理，任务一多就乱 |

**面试一句话**：crontab 是"定时触发器"，Airflow 是"任务编排调度平台"，核心差异在**依赖管理 + 失败重试 + 可视化**。

## 2. Airflow 架构：四个核心组件

```
用户
 │  WebUI（可视化：DAG 列表/运行状态/日志/失败重试）
 │
Scheduler（调度器：读 DAG 定义 → 到点生成任务实例 → 派发）
 │
Executor（执行器：把 Task 交给 Worker 真正去跑）
 │
Metadata DB（元数据库：记录任务状态/结果/历史，所有组件共享）
```

- **Scheduler**：大脑。持续扫描 DAG 定义，判断"哪个 DAG 到点了"，生成任务实例并派发给执行器。
- **Worker / Executor**：真正干活。Executor 负责分发，Worker 实际执行 Task。
- **WebUI**：可视化入口，看 DAG 图、运行状态、日志、手动触发/重跑。
- **Metadata DB**：默认 SQLite（生产用 MySQL/PostgreSQL）。所有任务状态、结果、历史都存这里。

## 3. 核心循环（调度闭环）

```
读取 DAG 定义
   → 到点生成 DagRun（DAG 运行实例）
   → Scheduler 把 Task 实例交给 Executor
   → Worker 执行
   → 执行结果写回 Metadata DB
   → WebUI 展示
```

## 4. 三大核心抽象（面试重点）

| 概念 | 一句话 | 类比 |
|------|--------|------|
| **DAG** | 任务编排蓝图：有哪些任务、谁先谁后、多久跑一次 | 菜谱的"顺序+步骤" |
| **Task** | DAG 里的一个节点，一次具体执行单元 | 菜谱里的"一步" |
| **Operator** | 这步"怎么做"的动作模板/类型 | "这步是炒还是蒸" |

**层次链**：`Operator（类/模板）→ 实例化成 Task（节点）→ Task 间用依赖连成 DAG（图）`

```python
task_a = BashOperator(task_id="抽数", bash_command="python extract.py", dag=dag)
task_b = PythonOperator(task_id="清洗", python_callable=clean, dag=dag)
task_c = BashOperator(task_id="汇总", bash_command="python agg.py", dag=dag)
task_a >> task_b >> task_c   # 依赖：抽数成功 → 清洗 → 汇总
```

## 5. 易混淆坑

- **DAG ≠ 跑一次**：DAG 是"定义"。每个调度周期生成一个 **DagRun**，真正干活的是 DagRun 里的 Task 实例。
- **Operator ≠ Task**：一个 `BashOperator` 类可被多个 `task_id` 实例化多次成多个 Task。**决定是不是同一个 Task 的是 `task_id`，不是 Operator 类型。**
- **DAG 必须无环**：有环 = 任务互相等对方 = 依赖死锁，Airflow 发现环直接报错拒绝。

## 6. 纸面落地：订单日报 DAG

```
DAG 名称：order_daily_report
schedule_interval = 每天 01:00
start_date = 昨天

Task1：task_id=抽数 ，BashOperator ，python extract.py   → 抽到 ODS
Task2：task_id=清洗 ，PythonOperator ，函数 clean        → 清洗到 DWD
Task3：task_id=汇总 ，BashOperator ，python agg.py       → 汇总到 DWS（供 ADS 报表）

依赖：抽数 >> 清洗 >> 汇总
```

分层对应：抽数→ODS、清洗→DWD、汇总→DWS（轻汇总），日报最终由 DWS 供 ADS（报表层）读取。

## 7. Day86 小测（已答全对）

1. crontab 失败不重试；Airflow 默认自动重试，重试耗尽→失败→告警→人工介入。
2. 派发任务给执行器 = **Scheduler**；记录任务结果 = **Metadata DB**。
3. DAG 每次调度触发生成的运行实例 = **DagRun**。
4. 一个 PythonOperator 被两个不同 task_id 使用 = **2 个 Task**（task_id 决定唯一性）。
5. Airflow 核心优势 = **DAG 依赖编排 + 失败自动重试**（+ 可视化）。

---

**产出**：notes/Day86-Airflow架构与DAG.md + scripts/day86/order_daily_report_dag.md（纸面 DAG 设计）
