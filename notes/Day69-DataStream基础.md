# Day69 · DataStream 基础（Source / 算子 / Sink + 第一个 Flink Java 流式程序）

> 模块六 · 实时数仓实战 Day2 | 配套脚本见 `scripts/day69/`（完整 Maven 工程）。
> 真实环境：Flink 1.19.1，Java 17 + Maven，socket 实时流 → 算子 → 文件 sink 跑通。

---

## 1. DataStream 编程模型

```text
DataStream = Flink 里流动的数据流（无界，一条一条）
Source（进）→ [算子1 → 算子2 → ...]（处理）→ Sink（出）
```

### 三大算子（面试必答）
| 算子 | 做什么 | 一进几出 |
|------|--------|----------|
| map | 一对一转换 | 1 → 1 |
| filter | 按条件过滤 | 1 → 0或1 |
| flatMap | 一条拆多条（句子拆词） | 1 → 0..N |

### Source / Sink
- Source：socket（nc）/ file / Kafka（生产最常用）
- Sink：print / 文件 / Kafka / MySQL

## 2. 批流统一（易混淆坑，Flink 1.19 重点）

```text
1.12 之前：DataStream（流）+ DataSet（批）两套 API
1.12 起：统一为 DataStream（批 = 有界流）——DataSet 废弃
1.19：DataSet API 已移除
```
> 面试一句话：Flink 用 DataStream 一套 API 统一批流——批处理=有界流，流处理=无界流。

## 3. 实操：socket → flatMap/map/filter → 文件（完整工程见 scripts/day69/）

核心代码：
```java
// Source：socket 实时流
DataStream<String> lines = env.socketTextStream("localhost", 9999);

// flatMap：一行 → 多个单词
DataStream<String> words = lines.flatMap((line, out) -> {
    for (String w : line.split(" ")) out.collect(w);
});

// map：单词 → (单词,1)，Lambda 类型擦除 → returns 显式指定
DataStream<Tuple2<String, Integer>> pairs = words
    .map(w -> Tuple2.of(w, 1))
    .returns(Types.TUPLE(Types.STRING, Types.INT));

// filter：只保留长度 > 1
DataStream<Tuple2<String, Integer>> filtered = pairs.filter(p -> p.f0.length() > 1);

// Sink：写文件（单并行 = 单文件）
filtered.writeAsText("/tmp/flink_socket_out").setParallelism(1);

env.execute("socket-wordcount");
```

### 运行流程
```bash
# 终端 A：数据源
nc -lk 9999
# 输入 hello flink / hi world

# 终端 B：提交
start-cluster.sh   # 若 8081 连接拒绝 = 集群没起
flink run -c com.example.SocketWordCount target/socket-word-1.0.jar
cat /tmp/flink_socket_out
# (hello,1) (flink,1) (hi,1) (world,1)
```

## 4. 踩坑记录（本日 4 个，全是面试素材）

| 坑 | 现象 | 解法 |
|----|------|------|
| Lambda 类型擦除 | returns 推断失败报错 | `.returns(Types.TUPLE(...))` |
| 集群没起 | 连接被拒绝 8081 | start-cluster.sh + jps 确认 |
| TM 未注册完 | NoResourceAvailable | 等 TM 起来再提交（日志确认 RUNNING） |
| writeAsText 单并行 | 输出是"单文件"不是目录 | 直接 cat 文件 |

> 面试一句话：Flink Lambda 算子返回自定义泛型时因类型擦除无法推断 → `.returns()` 显式声明。

---

## 今日面试考点清单
1. DataStream 形状？→ Source→算子链→Sink
2. 三算子进出？→ 1:1 / 1:0或1 / 1:N
3. 批流统一？→ 1.12 起一套 DataStream，1.19 DataSet 移除
4. 类型擦除？→ .returns() 显式指定
5. 两行输入 4 条输出？→ 每行拆 2 词共 4 条 + filter 全保留

## 易混淆坑
- 批流统一：批=有界流，不是两套 API
- writeAsText 单并行 = 单文件（vs WordCount 示例的时间桶目录）
- NoResourceAvailable ≠ 集群挂了，常是 TM 未注册完
