# 实时订单数仓 mini 项目 · 架构说明（简历雏形）

## 一、项目背景
离线数仓 T+1 出 GMV，满足不了实时大屏需求；构建秒级实时 GMV 管道，且与离线口径一致、结果可靠。

## 二、整体架构

| 层 | 技术/存储 | 职责 |
|----|----------|------|
| ODS | Kafka order_topic（3 分区） | 原始订单流接入，原样保留 |
| DWD | Flink SQL 视图 | 清洗、过滤 status=2（已支付口径统一） |
| DWS | Flink SQL TUMBLE 10s 窗口 | 轻度汇总：订单数 COUNT、GMV SUM |
| ADS | print sink（生产：MySQL/Redis/大屏） | 实时 GMV 结果输出 |
| 对账 | Python 对账脚本 | 实时 ADS vs 离线 ads_gmv_report 差异告警 |

## 三、数据流
Kafka(order_topic) → KafkaSource → DWD(WHERE status=2) → DWS(10s 窗口聚合) → ADS(print/落库) → 对账

## 四、关键设计
1. **口径统一**：GMV 只算 status=2，实时与离线同一口径（避免两套数字）
2. **容错 Exactly-Once**：Checkpoint(5s) + Kafka offset 存状态快照，故障续跑不丢不重
3. **可靠性**：事件时间 Watermark + allowedLateness 处理乱序/迟到；双链对账抓差异
4. **分层解耦**：DWD 口径集中，ODS 原始保留，下游复用（改口径不动下游）

## 五、技术栈
Flink 1.19（SQL + DataStream）、Kafka 3.7、MySQL（离线权威表）、Python（对账脚本）

## 六、本地 demo 与生产差距（面试加分认知）
- 处理时间窗口 → 生产用事件时间 + Watermark + allowedLateness
- print sink → 生产用 MySQL/Redis Sink + 两阶段提交事务
- 单机 standalone → 生产 YARN/K8s 自动资源管理（TM 自动拉起）
- VIEW 逻辑分层 → 生产 DWD/DWS 落 Kafka 主题物理分层 + 调度监控
