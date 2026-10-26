# Day74 · Kafka + Flink 管道（KafkaSource / offset 协同 / Exactly-Once）

> 模块六 · 实时数仓实战 Day7 | 配套脚本见 `scripts/day74/`（KafkaOrderAgg.java + README）。
> 真实环境：Flink 1.19.1 + Kafka 3.7.1，KafkaSource 读 order_topic → 10s 窗口聚合 → print 跑通。

---

## 1. Flink 读写 Kafka 的连接器
```text
Source（读）：KafkaSource（现代 API，旧 FlinkKafkaConsumer 已废弃）
Sink（写）：KafkaSink
并行度上限 = topic 分区数（一个分区一个 source 并行子任务）
```

## 2. offset 与 Checkpoint 协同（面试核心）

```text
开 Checkpoint：
  Kafka 消费位点（offset）作为状态存进 Checkpoint
  故障恢复：从 Checkpoint 恢复 → 连 offset 一起恢复 → 从上次位点继续读
  → 不丢、不重（配合 Sink 事务，端到端 Exactly-Once）

不开 Checkpoint：
  offset 由 Kafka auto.commit 管理 → 挂了可能丢/重
```

## 3. 端到端 Exactly-Once 三要素（面试必答，落地版）

```text
① Kafka Source：offset 存进 state（Checkpoint 管消费位点）
② 状态快照：Checkpoint 定期落盘
③ Kafka Sink：两阶段提交（事务消息，Checkpoint 完成才 commit）
```

## 4. 实操：KafkaOrderAgg.java（KafkaSource → 10s 窗口 → print）

```java
// pom.xml 依赖（注意独立版本号！）
org.apache.flink:flink-connector-kafka:3.2.0-1.19

// Kafka Source
KafkaSource<String> source = KafkaSource.<String>builder()
    .setBootstrapServers("127.0.0.1:9092")
    .setTopics("order_topic")
    .setGroupId("flink_group")
    .setStartingOffsets(OffsetsInitializer.latest())
    .setValueOnlyDeserializer(new SimpleStringSchema())
    .build();
env.fromSource(source, WatermarkStrategy.noWatermarks(), "kafka-order");
```

实测输出：Kafka 窗口 3 个各 1 单（599/99/99）——Kafka 进 → 窗口算 → 结果出。

## 5. 踩坑记录（本日 2 连）

| 坑 | 现象 | 解法 |
|----|------|------|
| connector 版本号写错 | Could not find flink-connector-kafka:1.19.1 | connector 独立版本号，Flink 1.19 用 3.2.0-1.19 |
| Kafka 非开机自启 | jps 没有 Kafka 进程 | 手动 zookeeper-server-start.sh + kafka-server-start.sh |

---

## 今日面试考点清单
1. 用什么读 Kafka？并行度上限？→ KafkaSource；分区数
2. offset 存哪？→ 开 checkpoint 存状态，恢复续读
3. 不开 checkpoint？→ auto.commit，可能丢/重
4. Exactly-Once？→ offset + 状态快照 + Sink 事务
5. connector 版本？→ 独立版本号（3.2.0-1.19）

## 易混淆坑
- flink-connector-kafka 版本 ≠ Flink 主版本（1.17 起独立）
- 并行度上限是分区数，不是消费者数
- "开 checkpoint" 是 Flink+Kafka 生产必配（否则 offset 无保障）
- latest() 从头/最新起点配置要按场景选（latest / earliest）
