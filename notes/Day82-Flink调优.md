# Day82 · Flink 调优（并行度 + 背压 + 状态后端 + Checkpoint 参数）

> 模块六 · 实时数仓实战 Day15 | 配套脚本见 `scripts/day82/`（TuningDemo.java + README）。
> 面试高频区：背压排查、状态后端选型、并行度设置。

---

## 1. 并行度 Parallelism

```text
并行度 = 一个算子被切成几个并行子任务（subtask）同时跑
slot   = TM 分给一个 subtask 的资源单位
```

设置优先级：**算子级 > 全局 env > 集群默认**
```java
env.setParallelism(4);        // 全局
source.setParallelism(3);     // 算子级
// flink run -p 4 xxx.jar
```

硬约束：**Kafka Source 并行度上限 = topic 分区数**（3 分区设 4 也只有 3 个有效）。

### 不能盲目调大的四个原因（易混淆坑）
1. **数据倾斜**：热点 key 全进同一 subtask，它跑满其他闲置
2. **shuffle 网络开销**：并行度越高，subtask 间数据交换/序列化成本越高
3. **资源约束**：总并行度 ≤ slot 总数，多了排队等 slot
4. **小流量任务**：并行度过大，调度开销 > 收益

## 2. 背压 Backpressure（面试链：现象→指标→定位→解法）

### 现象
下游处理不过来 → 输出队列堵满 → 反压上游变慢/阻塞；流处理不报错，只是吞吐掉、延迟涨、Checkpoint 变慢。

### 指标（Web UI 8081 → Job → SubTasks）
- BackPressured Time：被反压时间比例；OK(<50%) / LOW(50~80%) / HIGH(>80%)
- Records Received/Sent 速率：输入持续大于输出

### 定位
```text
Source → map → keyBy → window → Sink
看每条 edge：第一条 HIGH 边的【下游算子】就是瓶颈（下游堵才压上游）
```

### 原因 → 解法对照（面试必背）

| 原因 | 解法 |
|------|------|
| 下游外部存储逐条写（JDBC/Redis） | 攒批、批量写、异步 IO |
| 数据倾斜（热点 key） | key 加盐打散、两阶段聚合、rebalance |
| 并行度不足/CPU 跑满 | 瓶颈算子单独提并行度（别全局一刀切） |
| GC 频繁/堆内存紧张 | 调 Heap、对象复用、减少对象创建 |
| 状态过大、Checkpoint 慢 | RocksDB 增量快照、调 checkpoint 间隔 |
| 外部系统瓶颈 | 扩下游、批量客户端、异步化 |

## 3. 状态后端选型（面试二选一对比）

| | HashMapStateBackend（堆内） | EmbeddedRocksDBStateBackend（堆外+磁盘） |
|---|---|---|
| 状态位置 | JVM 堆内存 | 本地 RocksDB（堆外 + 磁盘 SST） |
| 容量 | 受堆内存限制，小状态 | GB/TB 级，大状态 |
| 访问 | 快（直接内存对象） | 稍慢（序列化读写磁盘） |
| Checkpoint | 全量快照 | **增量快照**（只传变更 SST） |
| 适用 | 小窗口、小 Keyed State、低延迟 | 大窗口聚合、大状态、Join/维表 |

> 坑：1.19 旧类名 MemoryStateBackend/FsStateBackend 已移除；现名 HashMap / EmbeddedRocksDB。

## 4. Checkpoint 关键参数
```java
env.enableCheckpointing(5000, CheckpointingMode.EXACTLY_ONCE); // 间隔5s + 语义
cfg.setCheckpointTimeout(60000);           // 快照超时 60s
cfg.setMinPauseBetweenCheckpoints(2000);   // 两次快照最小间隔，防互相挤压
cfg.setCheckpointStorage("file:///tmp/ckpt"); // 生产 hdfs:///...
```
- EXACTLY_ONCE：barrier 对齐，不丢不重；AT_LEAST_ONCE：可能重复但更快
- **间隔不是越短越好**：太短 → 快照互相挤压、占 IO/CPU、拖慢处理

## 5. 内存模型（了解层）
```text
TaskManager = JVM Heap（用户代码 + HashMap 状态）
            + Network Memory（shuffle 缓冲）
            + Managed Memory（RocksDB 本地内存/批量算子哈希排序）
            + Metaspace/框架开销
```
调优口诀：
- CPU 打满 → 加瓶颈算子并行度
- 堆 OOM / GC 频繁 → 调 Heap、对象复用
- 状态过大 → RocksDB + 扩磁盘/Managed Memory
- 网络缓冲不足 → 调 Network Memory

## 6. 实操 TuningDemo.java 要点
- 配置段：EXACTLY_ONCE、超时 60s、最小间隔 2s、checkpointStorage、固定延迟重启 3 次
- 演示环境限制：1 TM × 1 slot，并行度调优无法真正多并行；重点会写参数 + 会看 UI
- UI 路径：8081 → Running Job → SubTasks → Backpressure / Metrics
- 快照目录：find /tmp/ckpt-tuning -type d

---

## 今日面试考点清单
1. 并行度定义 + Source 上限？→ subtask；分区数
2. 并行度盲目调大的代价？→ 倾斜/shuffle/资源/调度
3. 背压现象与定位？→ HIGH 边下游算子
4. 两种状态后端选型？→ 小 HashMap / 大 RocksDB
5. Checkpoint 间隔与最小间隔？→ 防挤压

## 易混淆坑
- 背压是慢/堵，不是报错；定位永远看 HIGH 边的下游
- 提并行度先提瓶颈算子，不要全局一刀切
- RocksDB 优势是增量快照 + 容量，代价是访问速度
- slot 总数是硬天花板，并行度超过只会排队
