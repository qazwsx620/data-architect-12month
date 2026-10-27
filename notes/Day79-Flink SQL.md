# Day79 · Flink SQL（声明式 + 动态表 + 实时窗口聚合实操）

> 模块六 · 实时数仓实战 Day12 | 配套脚本见 `scripts/day79/`（FlinkSqlGmv.java + README）。
> 真实环境：Flink 1.19.1 + Kafka 3.7.1，Flink SQL 窗口聚合 GMV 跑通（+I[窗口, 599.0, 1]）。

---

## 1. Flink SQL vs DataStream API（面试必答）

```text
Flink SQL：声明式"算什么"——引擎优化执行，一行 SQL 搞定窗口聚合
DataStream API：命令式"怎么算"——自己组装算子（map/filter/window/匿名类）
```

## 2. 动态表 Dynamic Table（面试必答）

```text
流无限 → 表持续更新 → 动态表
每个时刻的动态表 = 该时刻流的快照（插入/更新/删除）
SQL 查动态表 → 结果也是动态表 → 持续输出更新

静态表（批）：查一次，结果不变
动态表（流）：持续更新，结果不断刷新
```

## 3. 选型（面试必答）

| 场景 | 选谁 |
|------|------|
| 常规窗口/聚合/过滤 | SQL（简单、声明式、引擎优化、生产主流） |
| 复杂业务/自定义算子 | DataStream（state 细节、底层控制） |
| 趋势 | 能用 SQL 用 SQL |

## 4. 实操：FlinkSqlGmv.java

```java
// pom 追加：flink-table-api-java-bridge + flink-table-planner-loader（1.19.1）

// Kafka 源表（CSV: user_id,amount,status；proc_time = 处理时间）
CREATE TABLE order_tb (
  user_id STRING, amount DOUBLE, status INT,
  proc_time AS PROCTIME()
) WITH ('connector'='kafka', 'topic'='order_topic',
  'properties.bootstrap.servers'='127.0.0.1:9092',
  'properties.group.id'='flink_sql',
  'scan.startup.mode'='latest-offset', 'format'='csv')

// print 结果表
CREATE TABLE gmv_sink (...) WITH ('connector'='print')

// 一行 SQL 窗口聚合（GMV，status=2 口径）
INSERT INTO gmv_sink
SELECT TUMBLE_START(proc_time, INTERVAL '10' SECOND),
       TUMBLE_END(proc_time, INTERVAL '10' SECOND),
       SUM(amount), COUNT(*)
FROM order_tb WHERE status = 2
GROUP BY TUMBLE(proc_time, INTERVAL '10' SECOND)
```

实测输出：`+I[2026-10-27T08:29:10, 2026-10-27T08:29:20, 599.0, 1]`
- `+I` = 插入模式（动态表更新可见）
- GMV=599（199 未支付被 WHERE 过滤）

## 5. 踩坑记录（本日 1 连）
- Table API 不在 flink-streaming-java 里：需追加 flink-table-api-java-bridge + flink-table-planner-loader 依赖
- jar 明显变大（planner loader 打进 uber jar）

---

## 今日面试考点清单
1. SQL vs DataStream？→ 声明式 vs 命令式
2. 动态表？→ 流上持续更新的表（快照演进）
3. 选型？→ 常规用 SQL，复杂用 DataStream
4. TUMBLE？→ 按时间窗口分组
5. +I？→ 插入模式，动态表可见性

## 易混淆坑
- TUMBLE 按时间窗口分组，不是按业务 id
- 动态表持续更新 ≠ 静态表一次性结果
- SQL 也有"状态"：窗口/聚合在动态表里由引擎管理（隐藏细节）
- print connector 输出格式 +I/-U/+U/-D（Insert/Update/Delete 可见性）
