# Day89 总结笔记：元数据平台（Atlas / DataHub）

> 日期：2026-11-05 ｜ 模块七：数据平台工程 ｜ 状态：✅ 理论 + 方案设计

## 一、为什么要元数据平台（对比 Day64 手工采集）

| Day64 手工采集痛点 | 生产后果 | 元数据平台能力 |
|---|---|---|
| 手工跑 SQL 扫表结构 | 元数据滞后，影响分析失真 | 自动采集（Crawler）|
| 手画 mermaid 血缘 | 漏分支（Day64 漏了 dws_product_daily）| 自动解析血缘 |
| 业务元数据散在文档 | 口径不统一、找不到 owner | 统一登记 + 分类标签 + owner |
| 无统一查询入口 | 翻文档、无权限无审计 | 服务化：搜索/API/权限/审计 |

一句话：**手工采集是快照，元数据平台是持续同步的数据资产目录**。
价值三个词：**可发现、可理解、可信任**。

## 二、三层架构（采集 → 存储 → 服务）

```
数据源（MySQL/Hive/Airflow/ETL脚本）
  → 采集层（Crawler Pull / Hook Push / SQL 解析血缘）
  → 存储层（实体 Entity - 关系 Relationship - 分类 Classification - 属性）
  → 服务层（搜索 / API / 血缘图 / 权限审计）
  → 消费方（开发 / 业务 / 治理）
```

- **采集层**：Pull（Crawler 定时扫）适合技术元数据；Push（Hook/API 上报）适合业务元数据和变更事件
- **存储层**：实体-关系模型是核心抽象，**血缘 = 实体间的关系**；分类 = 标签（核心表/PII/临时表）
- **服务层**：搜索（找数）、影响分析/血缘图（改数）、API、权限审计

## 三、Atlas vs DataHub

| 维度 | Apache Atlas | DataHub |
|---|---|---|
| 出身 | Hadoop 生态，Hive Hook 采血缘 | LinkedIn 开源，现代数据栈 |
| 强项 | Hadoop 血缘深、分类分级/合规审计 | UI/搜索现代、连接器多（MySQL/Airflow/dbt）、实时元数据事件 |
| 部署 | 重（JanusGraph+HBase+Solr） | 相对现代（Metadata Service+ES+Kafka） |
| 选型 | Hive/Spark 数仓 + 合规要求 | 多源异构 + Airflow/MySQL/云 + 要好用 |

## 四、订单数仓方案（scripts/day89/元数据平台方案.md）

- 采集：技术元数据 Pull（每日）+ 任务血缘读 DAG + 表血缘 SQL 解析 + 业务元数据 Push 登记
- 存储：实体（表/字段/DAG/task）+ 关系（表→表血缘）+ 分类（核心表 / **PII：biz_user、收货地址、dwd_order_detail**）
- 服务：搜索"GMV 口径"直达表+owner；影响分析查改表波及；API 卡点；权限审计
- 选型：**DataHub**

## 五、今日小测试（5 题全过）

1. 元数据平台解决什么 → 自动采集/自动血缘/统一登记/服务化（4 痛点对应）
2. 三层架构 + Pull/Push 分工
3. Atlas（Hive/Spark+合规）vs DataHub（多源/现代 UI）
4. DAG 只采任务级（task→task），表级必须 SQL 解析（INSERT...SELECT）
5. 血缘=关系（Relationship），PII 标签=分类（Classification）

## 六、易混淆坑

- Atlas 血缘靠 Hook 采集执行计划，不是纯 SQL 解析
- DataHub "实时"指元数据变更事件流，不是数据实时
- 元数据平台 ≠ 完整数据治理平台（质量/安全/权限要另配）
- PII 会随 ETL 扩散：源表打了标，DWD 落同样字段也要标

## 七、明日预告

模块七继续（按计划表 Day90 内容）
