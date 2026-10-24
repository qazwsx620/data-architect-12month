# Day70 · 窗口（滚动/滑动/会话 + 增量/全量聚合 + 订单流实操）

> 模块六 · 实时数仓实战 Day3 | 配套脚本见 `scripts/day70/`（OrderWindowCount.java）。
> 真实环境：Flink 1.19.1，socket 订单流 → 滚动/滑动窗口聚合跑通。

---

## 1. 为什么需要窗口
无界流没法整体聚合 → 按时间/数量切"有界"窗口，在窗口内聚合。

## 2. 三种窗口（面试必答）

| 窗口 | 特点 | 例子 |
|------|------|------|
| 滚动 Tumbling | 固定大小、不重叠 | 每 10s：0-10s、10-20s |
| 滑动 Sliding | 固定大小 + 滑动步长、**可重叠** | 窗 10s 步长 5s：0-10s、5-15s（一条数据属 2 窗） |
| 会话 Session | 按"不活跃间隔"切、无固定大小 | 间隔 >30s 算新会话 |

## 3. 窗口函数（怎么算）

```text
增量聚合：来一条算一条（ReduceFunction/AggregateFunction）——效率高，生产默认
全量聚合：窗口攒齐后一起算（ProcessWindowFunction）——需要全量时用（排序/自定义输出）
```

## 4. 触发边界（易混淆坑）
滚动 10s：收集 [0s,10s)，10s 边界触发；9.9s 进 [0,10)，10s 进 [10,20)。

## 5. 实操：socket 订单流窗口聚合（OrderWindowCount.java）

```text
输入格式：user_id,amount（1001,2999）
① 滚动 10s：windowAll(TumblingProcessingTimeWindows.of(Time.seconds(10)))
② 滑动 10s/5s：windowAll(SlidingProcessingTimeWindows.of(Time.seconds(10), Time.seconds(5)))
apply 全量聚合（匿名类 AllWindowFunction 避免类型擦除）
print() 输出 → TaskManager .out 日志
```

### 实测输出（关键差异可见）
```text
滚动10s: 订单数=2 金额=3098（2999+99 同一窗，不重叠）
滚动10s: 订单数=1 金额=118
滚动10s: 订单数=2 金额=458（399+59）
滑动10s/5s: 订单数=1 金额=2999   ← 同一条订单出现在相邻窗口
滑动10s/5s: 订单数=2 金额=3098
滑动10s/5s: 订单数=1 金额=99    ← 重叠
```

## 6. 踩坑记录（面试素材）

| 坑 | 现象 | 解法 |
|----|------|------|
| apply lambda 类型擦除 | Collector 泛型缺失报错 | 改匿名类 AllWindowFunction（泛型完整） |
| 唯一 slot 被占 | 二次提交 NoResourceAvailable | 1 TM × 1 slot 只能跑 1 个作业；先 flink cancel 再提交 |
| print 输出位置 | 控制台看不到 | 在 TaskManager .out 日志：tail -f /opt/flink/log/flink-*-taskexecutor-*.out |

> 面试一句话：**窗口把无界流切成有界段聚合；滚动不重叠、滑动重叠、会话按空闲切**。

---

## 今日面试考点清单
1. 三种窗口？→ 滚动/滑动/会话
2. 滑动两参数？→ 大小+步长，重叠=一条数据进两窗
3. 增量 vs 全量？→ AggregateFunction 来一条算一条 vs ProcessWindowFunction 攒齐算
4. 触发边界？→ 9.9s 进 [0,10)，10s 进 [10,20)
5. 二次提交没资源？→ 唯一 slot 被前作业占用，先 cancel

## 易混淆坑
- 滑动窗口"重叠"是核心特性（vs 滚动）
- print 输出在 .out 日志，不在提交终端
- 本地集群 1 slot 限制：同时只能 1 个流作业
