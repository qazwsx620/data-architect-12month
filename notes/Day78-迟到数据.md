# Day78 · 迟到数据（Watermark 之外的处理链 + allowedLateness 机制）

> 模块六 · 实时数仓实战 Day11 | 配套脚本见 `scripts/day78/`（LateDataWindow.java + README）。
> 真实环境：Flink 1.19.1，事件时间窗口 + allowedLateness 5s + 侧输出流，重触发链 + 旁路收集跑通。

---

## 1. Watermark 与迟到数据（衔接 Day71）

```text
Watermark = 最大事件时间 - 容忍（如 3s）
  → 只解决"容忍范围内的乱序"
迟到数据 = 容忍之外的乱序数据（窗口已触发后才到）
```

## 2. 迟到数据三种处理（面试必答）

```text
① 直接丢弃（默认）：窗口已触发，不再进窗
② allowedLateness(n)：窗口触发后再等 n 秒
   → 迟到数据仍能进窗，并【重新触发】窗口计算（结果更新）
③ 侧输出流 sideOutputLateData：
   → 超过 allowedLateness 还迟到的数据进侧输出流（旁路）
   → 单独收集，用于对账/补算/告警
```

## 3. 清窗机制（易混淆坑，面试细节）

```text
allowedLateness 不是"墙钟等 N 秒"！
清窗条件：Watermark ≥ 窗口结束时间 + allowedLateness
→ 在 Watermark 推过 end+allowedLateness 之前，窗口持续收迟到数据
→ 要让窗口关闭，必须来一条大事件时间数据把 Watermark 推过去
```

## 4. 实操：LateDataWindow.java

```java
OutputTag<Tuple3<Integer, Double, Long>> lateTag = new OutputTag<>("late") {};
// 注意：侧输出流 tag 类型必须与窗口输入类型一致（Tuple3），String 会编译错！

.windowAll(TumblingEventTimeWindows.of(Time.seconds(10)))
.allowedLateness(Time.seconds(5))
.sideOutputLateData(lateTag)
.apply(AllWindowFunction...)
```

### 实测（关键顺序）
```text
1,10000 / 2,11000 / 3,12000 / 4,25000 → 触发：3 单 33000（Watermark=22000）
5,14000    → 重触发：4 单 47000（窗口存活：22000 < 25000）
6,12000 / 7,12000 → 重触发 59000 / 71000（都未推高 Watermark）
8,30000    → Watermark=27000 ≥ 25000 → 清窗
9,13000    → 迟到旁路: order=9（窗口已清）
```

## 5. 踩坑记录（本日 2 连）
- **侧输出流 tag 类型错**：`OutputTag<String>` vs 窗口输入 Tuple3 → 编译不兼容；tag 类型必须与流元素一致
- **allowedLateness 误解**：以为"墙钟等 5s"就清窗；实际要 Watermark 推过 end+allowedLateness

---

## 今日面试考点清单
1. 迟到数据？→ 容忍外、触发后才到
2. 三种处理？→ 丢弃 / allowedLateness / 侧输出流
3. 清窗公式？→ Watermark ≥ end + allowedLateness
4. 为什么 14000 进窗 13000 旁路？→ 到达时窗口是否已清
5. 旁路用途？→ 对账 / 补算 / 告警

## 易混淆坑
- allowedLateness ≠ 墙钟计时（要 Watermark 推进才清窗）
- 侧输出流 tag 类型 = 流元素类型（不是输出类型）
- "窗口已触发" ≠ "窗口已清除"（触发后 allowedLateness 内还能进）
- 迟到数据进侧输出流后不会自动回补（要手动对账/补算）
