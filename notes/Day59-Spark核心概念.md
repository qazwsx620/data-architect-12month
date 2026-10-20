# Day59 · Spark 核心概念（架构 + 三种抽象 + 宽窄依赖 + 真实环境实操）

> 模块五 · 大数据数仓进阶 Day4（加量版）| 配套脚本见 `scripts/day59/`。
> 里程碑：**真实安装 Spark 3.5.1 成功**，从模拟路线转入真实 Spark 实操。

---

## 1. Spark 架构（面试必答）

```text
Driver（主控大脑）
  ├── 拆分任务、调度、追踪状态
  └── 把计算计划发给 Executor
Executor（干活的工人）
  ├── 集群中每台机器多个 Executor
  └── 真正并行执行计算（内存缓存数据）
Cluster Manager（资源调度）
  └── 分配 CPU/内存给 Driver 和 Executor
```

## 2. Spark 为什么比 MapReduce 快（核心面试）

| 原因 | 说明 |
|------|------|
| ① 内存计算 | 中间结果存内存，MapReduce 每步落磁盘（磁盘IO最大开销） |
| ② DAG 优化 | 计算画成 DAG，合并步骤、减少 shuffle |
| ③ 任务级并行 | Executor 内多线程并行（MapReduce 起进程，开销大） |

## 3. 三种数据抽象

```text
RDD      → 分布式集合，不可变，可容错（灵活但慢，无优化）
DataFrame → 带 schema（列名+类型），Catalyst 优化器自动优化（快）
DataSet  → Scala/Java 类型安全版（Python 用 DataFrame）
```

## 4. 宽窄依赖 + Stage + Shuffle（面试必答）

```text
窄依赖：父分区只被 1 个子分区用（map/filter）→ 无 shuffle，可流水线
宽依赖：父分区被多个子分区用（groupBy/join）→ shuffle，要等全部数据
Stage 划分：宽依赖切一刀
Shuffle：数据跨 Executor 按 key 哈希重新分布
```

**血缘与容错**：RDD 记录依赖链（血缘），分区丢失沿血缘重算恢复，不用全量备份——这就是"弹性"。

## 5. 环境安装（真实落地）

```bash
sudo apt install -y openjdk-17-jdk-headless        # Java 17
wget -c https://mirrors.huaweicloud.com/apache/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz
sudo mkdir -p /opt/spark && sudo tar -xzf spark-3.5.1-bin-hadoop3.tgz -C /opt/spark --strip-components=1
# 配置 JAVA_HOME / SPARK_HOME / PATH 到 ~/.bashrc
spark-shell --version   # ✅ Spark 3.5.1 + Scala 2.12.18
```

## 6. 真实实操结果（Spark Shell）

### 内存数据 → DataFrame
```scala
val df = Seq((30001,1001,2999.00,"已支付"),(30002,1002,99.00,"未支付"),
             (30003,1003,118.00,"已支付")).toDF("order_id","user_id","amount","status_name")
```

### 读业务 CSV（inferSchema 自动推断类型）
```scala
val orders = spark.read.option("header","true").option("inferSchema","true")
  .csv("/home/vboxuser/py_learn/etl_project/input/biz/biz_order.csv")
// schema: order_id:int, user_id:int, product_id:int, amount:double, status:int, order_date:date
```

### DataFrame 基础操作
```scala
orders.filter("amount > 100").show()              // 5 行
orders.groupBy("status").count().show()           // 1:2, 2:5, 3:1
```

## 7. Spark 版 DWD 清洗 + GMV 复现（连接模块四）

```scala
import org.apache.spark.sql.functions._
val dwd = orders.withColumn("status_name",
  when(col("status") === 1, "未支付").when(col("status") === 2, "已支付")
  .otherwise("已取消"))
// 映射：1未支付 / 2已支付 / 3已取消（模块四锚点）
val daily = dwd.filter("status_name = '已支付'")
  .groupBy("order_date")
  .agg(sum("amount").as("gmv"), count("order_id").as("order_cnt"))
  .orderBy("order_date")
```
**结果与模块四 MySQL 完全一致**：10-10 GMV=3117(2单)、10-11=6398(2单)、10-12=59(1单) —— 清洗/口径能力无缝迁移 Spark。

---

## 今日面试考点清单
1. Spark 三角色？→ Driver 调度 / Executor 并行 / Cluster Manager 资源
2. 为什么快？→ 内存 + DAG 少 shuffle + 线程并行
3. RDD/DataFrame/DataSet？→ 灵活慢 / schema 快 / 类型安全
4. 宽依赖/Stage/shuffle？→ groupBy/join 触发，宽依赖切 Stage，shuffle 按 key 搬运
5. 血缘容错？→ 依赖链记录，丢了沿血缘重算

## 易混淆坑
- withColumn=加列；when=case；otherwise=default
- DataFrame 比 RDD 快不是语言差异，是 schema+Catalyst 优化
- 窄依赖不 shuffle（map/filter），宽依赖才 shuffle（groupBy/join）
- Spark 单机 local[*] 模式没集群也能跑（本环境）
