# Day83 实时面试题集（1）口述稿 —— Kafka/Flink 高频 20 题

> 用法：对着题目自己口述一遍，卡住的地方回到笔记 Day83 补；薄弱项每天过一遍。

## Kafka 10 题
1. **Kafka 为什么快？** 顺序写磁盘 + 页缓存 + 零拷贝 sendfile + 分区并行 + 批量压缩
2. **四者关系？** topic 逻辑分类 / partition 并行单元 / offset 分区内递增序号 / 副本冗余备份（leader 读写、follower 同步）
3. **消费组？** 同分区同组一个消费者；最大有效消费者数=分区数；组间互不影响
4. **三种语义？** at-most-once 可能丢；at-least-once 可能重复；exactly-once 幂等+事务（Flink 端到端三段式）
5. **offset？** __consumer_offsets 主题；自动提交可能重复、手动提交可控；Flink 存状态随 checkpoint
6. **Rebalance？** 加入/退出/心跳超时/超 poll 间隔/扩分区触发；期间暂停消费可能重复
7. **有序性？** 分区内有序；跨分区无序；按键有序折中；全局有序单分区
8. **积压？** consumer-groups describe 看 lag；加消费者/优化消费/扩分区/提并行度
9. **副本链？** leader 读写、follower 同步、ISR 同步集合、LEO 下一条 offset、HW 消费者可见水位
10. **分区规划？** ≥ 下游并行度；不过多；只加不减

## Flink 10 题
1. **三种窗口？** 滚动不重叠 / 滑动可重叠 / 会话按不活跃间隔
2. **三种时间？** 事件/处理/摄入；处理时间不感知发生时刻会算错窗口
3. **Watermark？** 水位线；触发=watermark≥窗口结束；清窗=watermark≥结束+allowedLateness
4. **迟到三层？** 丢弃 / allowedLateness 重触发 / 侧输出流；清窗条件同上
5. **状态类型？** Value 单值 / List 列表 / Map KV；按 key 隔离、参与快照
6. **Exactly-Once？** source offset + checkpoint 状态 + sink 两阶段提交
7. **重启策略？** NoRestart/FixedDelay/FailureRate/ExponentialDelay；从最近 checkpoint 恢复
8. **keyBy 与倾斜？** key 哈希路由同 key 同 subtask；加盐两阶段聚合/热点单独处理
9. **ckpt vs savepoint？** 自动容错 vs 手动运维
10. **背压？** UI 看 HIGH 边下游；攒批异步/加盐/提并行度

## 薄弱项回炉（每天过一遍）
- [ ] offset 存哪（__consumer_offsets）与手动提交 API
- [ ] keyBy 哈希路由为什么保证同 key 同 subtask
- [ ] Flink 端到端 Exactly-Once 三段式
