# Day72 · 状态与容错（State + Checkpoint + Exactly-Once + 重启策略）

> 模块六 · 实时数仓实战 Day5 | 配套脚本见 `scripts/day72/`（KeyedStateCount.java）。
> 真实环境：Flink 1.19.1，ValueState 按用户累计 + Checkpoint + 杀 TM 故障实验。

---

## 1. 为什么需要状态
流处理逐条处理，但累计/去重/会话要"记住前面结果" → 状态（State）。

## 2. 状态类型（面试必答）

| 状态 | 存什么 | 场景 |
|------|--------|------|
| ValueState | 单个值 | 累计计数/最新值 |
| ListState | 元素列表 | 窗口收集/历史列表 |
| MapState | KV 映射 | 去重/分组聚合 |

> 一般配 keyBy 用（Keyed State）：每个 key 一份独立状态（如每个 user_id 的累计金额）。

## 3. Checkpoint（容错核心）

```text
Checkpoint = 定期把【状态 + 数据进度】做分布式快照存下来
故障恢复：作业挂了 → 从最近 Checkpoint 恢复 → 不丢、不重

Exactly-Once 三要素：
  ① Kafka offset（Source 消费位点）
  ② 状态快照（Checkpoint）
  ③ Sink 事务提交（两阶段）
```

## 4. 重启策略
固定延迟（FixedDelay）/ 失败率（Failure Rate）/ 不重启（None）。

## 5. 实操：ValueState 按用户累计（KeyedStateCount.java）

```java
// Checkpoint 每 5s + 固定延迟重启
env.enableCheckpointing(5000);
env.setRestartStrategy(RestartStrategies.fixedDelayRestart(3, Duration.ofSeconds(5)));

// keyBy(user_id) + ValueState 累计
orders.keyBy(t -> t.f0).process(new KeyedProcessFunction<...>() {
    private ValueState<Double> acc;
    open() { acc = getRuntimeContext().getState(new ValueStateDescriptor<>("acc", Types.DOUBLE)); }
    processElement() { acc.update(acc.value() + v.f1); ... }
}).print();
```

实测：1001→2999→3098→3498（ValueState 每个用户独立累计）。

## 6. 故障实验（面试金句素材）

```text
实验：pkill -9 -f TaskManagerRunner 杀 TM → 作业未能自动恢复

根因：standalone 模式 TM 是【手动启动的静态资源】，被杀不会自动拉起
     → 作业重启也拿不到 slot → 3 次重试耗尽 → FAILED

结论：生产用 YARN/K8s 模式，由资源管理器自动拉起 TM/容器
     → 这是生产不用 standalone 的核心原因之一
```

## 7. 踩坑记录
- pkill -9 杀 TM：作业不会自动恢复（无 slot），需手动 /opt/flink/bin/taskmanager.sh start
- flink list 确认作业状态；FAILED 后重新提交（本次未做 -s checkpoint 恢复，简化）
- 本地模式 checkpoint 文件在 /tmp flink 临时目录，未配持久化目录

---

## 今日面试考点清单
1. 为什么状态？→ 累计/去重/会话要记前面结果
2. 三状态类型？→ 单值/列表/KV
3. Checkpoint？→ 状态+进度快照，故障恢复不丢不重
4. Exactly-Once？→ offset + 状态快照 + Sink 事务
5. 杀 TM 不恢复？→ standalone 静态资源，生产 YARN/K8s 自动补

## 易混淆坑
- 状态是"流计算记住过去"的机制（vs 无状态算子）
- Checkpoint 恢复的是"状态+进度"，不是重放全部数据
- standalone TM 不自动拉起 ≠ YARN/K8s 自动补节点
- 重启策略决定"重试几次/间隔"，配合 Checkpoint 才有效
