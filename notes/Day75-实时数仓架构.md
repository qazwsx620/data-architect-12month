# Day75 · 实时数仓架构（四层分层 + 实时vs离线 + 实时GMV实操）

> 模块六 · 实时数仓实战 Day8 | 配套脚本见 `scripts/day75/`（RealTimeGmv.java + README）。
> 真实环境：Flink 1.19.1 + Kafka 3.7.1，ODS→DWD→DWS/ADS 实时 GMV 管道跑通（GMV=698，199 被过滤）。

---

## 1. 实时数仓分层（复用离线思想，搬到流上）

```text
ODS（原始层）：Kafka topic —— 原始订单流（如 order_topic）
DWD（明细层）：清洗/规范化 —— 解析字段、过滤无效数据（如 status=2）
DWS（汇总层）：按维度轻度聚合 —— 窗口聚合（订单数/金额）
ADS（应用层）：最终结果 —— 实时 GMV、实时大屏
```

> 面试一句话：实时数仓把离线的分层思想搬到流上——存储从 Hive 表换成 Kafka topic/状态，计算从批量 SQL 换成流式 Flink。

## 2. 实时 vs 离线对比（面试必答）

| 维度 | 离线数仓 | 实时数仓 |
|------|----------|----------|
| 时效 | T+1 天 | 秒/分钟级 |
| 存储 | Hive/数仓表（HDFS） | Kafka topic / Flink 状态 |
| 计算 | 批量 SQL（Spark/Hive） | 流式 Flink |
| 数据 | 全量快照 | 增量流 |
| 口径 | 可重跑、准确 | 窗口近似、低延迟 |

> 补充：Lambda 架构 = 实时+离线双链路合并；Kappa = 纯实时单链路（Day76 细讲）。

## 3. 实操：实时 GMV（RealTimeGmv.java）

```java
// ODS：Kafka 读订单原始流（user_id,amount,status）
// DWD：filter(t -> t.f2 == 2)   ← 只留已支付（GMV 口径，与离线一致）
// DWS/ADS：10s 窗口 sum(amount)
```

输入：2001,599,2 / 2002,199,1 / 2003,99,2
输出：**实时GMV 订单数=2 GMV=698.0**（599+99，199 未支付被过滤）

## 4. 口径统一（工程意义，面试加分）
实时和离线 GMV 口径必须一致（status=2），否则：
实时报表和离线报表对不上 → 同一指标两套数字 → 业务无法信任
（这就是数仓"口径统一/指标同源"的核心价值）

## 5. 踩坑记录（本日 1 连）
- 旧作业未 cancel：提交新作业前 `flink list` + `flink cancel <JobID>`
- **输出前缀可区分作业**：Kafka窗口=Day74 旧作业（不读 status）；实时GMV=本日新作业

---

## 今日面试考点清单
1. 实时四层？→ ODS/DWD/DWS/ADS 各做什么
2. 实时 vs 离线？→ 存储/计算引擎/时效
3. GMV 口径？→ status=2，与离线统一
4. 为什么统一口径？→ 防止同一指标两套数字
5. 怎么确认在跑哪个作业？→ flink list + 输出前缀

## 易混淆坑
- 实时四层≠离线四层：层名同，载体不同（Kafka/状态 vs Hive 表）
- GMV 永远用 status=2（锚点：2 谐音"成双"=已支付）
- 提交前必须 flink list，1 slot 只能跑 1 个作业
- 输出前缀是判断"哪个作业在跑"的快速手段
