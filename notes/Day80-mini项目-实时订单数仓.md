# Day80 · mini项目：实时订单数仓（四层链路串讲 + 项目雏形）

> 模块六 · 实时数仓实战 Day13 | 配套脚本见 `scripts/day80/`（FlinkSqlDw.java + README + project_arch.md）。
> 真实环境：Flink 1.19.1 SQL + Kafka 3.7.1，一个作业串起 ODS→DWD→DWS→ADS，实时 GMV 输出。

---

## 1. 项目架构（real-time-order-dw）

```text
Kafka order_topic（ODS 原始订单流：user_id,amount,status）
        │  KafkaSource（offset 由 Checkpoint 管）
        ▼
Flink SQL  DWD 明细层：清洗 + 过滤 status=2（只留已支付，口径统一）
        ▼
Flink SQL  DWS 汇总层：TUMBLE 10s 窗口（订单数 COUNT / GMV SUM）
        ▼
Flink SQL  ADS 应用层：实时 GMV（print sink；生产落 MySQL/Redis/大屏）
        ▼
对账层：ADS 实时 vs MySQL ads_gmv_report 离线（Day76 reconcile_check.py）

容错：enableCheckpointing(5000) → offset + 状态快照（Exactly-Once 基础）
```

## 2. 组件对照（所学知识点落地）

| 项目层 | 组件/技术 | 对应 Day |
|--------|-----------|---------|
| 接入 | Kafka order_topic（3 分区） | Day73/74 |
| 计算 | Flink 1.19 SQL | Day79 |
| DWD | WHERE status=2 口径统一 | Day75/77 |
| DWS | TUMBLE 10s 窗口聚合 | Day70/79 |
| 容错 | Checkpoint 5s + offset 管理 | Day72/74 |
| 对账 | 实时 vs 离线脚本 | Day76 |
| 迟到 | allowedLateness（生产配置） | Day78 |

## 3. 实操：FlinkSqlDw.java（CREATE VIEW 分层）

```java
// ODS：Kafka 源表 order_tb
// DWD：CREATE VIEW dwd_order AS SELECT ... FROM order_tb WHERE status = 2
// DWS：CREATE VIEW dws_gmv AS SELECT TUMBLE_START/END, SUM(amount) gmv, COUNT(*) cnt
//      FROM dwd_order GROUP BY TUMBLE(proc_time, INTERVAL '10' SECOND)
// ADS：CREATE TABLE ads_sink (... ) WITH ('connector'='print')
//      INSERT INTO ads_sink SELECT * FROM dws_gmv
```

实测输出（4001,599,2 / 4002,199,1 / 4003,99,2 / 4004,300,2）：
```text
+I[10:42:00~10:42:10, 599.0, 1]
+I[10:42:20~10:42:30, 99.0, 1]
+I[10:42:30~10:42:40, 300.0, 1]
# 199 未支付被 DWD 过滤（status=2 口径）
```

## 4. 分层为什么有价值（面试答题点）

```text
- 口径集中：status=2 过滤只写一次（DWD），DWS/ADS 复用
- 原始数据保留：ODS 原样不加工，可回溯重跑
- 解耦：改口径只动 DWD，下游不动
- 复用：DWS 一张汇总结果可服务多个 ADS 报表
```

## 5. 面试讲项目框架（简历可直接用）

```text
① 背景：实时 GMV 大屏需求（离线 T+1 不满足时效）
② 架构：Kafka → Flink SQL 四层（ODS/DWD/DWS/ADS）
③ 关键设计：
   - 口径：GMV 只算 status=2，实时离线统一
   - 容错：Checkpoint + offset 协同保 Exactly-Once
   - 可靠性：窗口迟到处理 + 双链对账
④ 成果：秒级 GMV 输出，实时离线对账一致
```

---

## 今日面试考点清单
1. 四层职责？→ 原始/清洗/汇总/应用
2. 容错两要素？→ Checkpoint + offset 协同
3. DWD 为什么单独过滤？→ 口径集中复用 + 解耦
4. 项目关键设计？→ 口径 / 容错 / 可靠性
5. 对账存在意义？→ 实时近似 ≠ 离线准确

## 易混淆坑
- VIEW 分层是逻辑视图，不是物理落表（生产 DWD/DWS 会落 Kafka 主题/存储）
- print sink 仅教学演示，生产 ADS 落 MySQL/Redis/ES
- mini 项目用处理时间窗口；生产需事件时间 + Watermark + allowedLateness
- 项目讲述先架构后细节，不要一上来讲 API
