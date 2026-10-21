# Day60 · Spark SQL 实操（SparkSession + 临时视图 + SQL 查询 + MySQL 读写）

> 模块五 · 大数据数仓进阶 Day5（加量版）| 配套脚本见 `scripts/day60/`。
> 真实环境：Spark 3.5.1 + MySQL 8.0（dw_project），Spark ↔ MySQL 双向打通。

---

## 1. SparkSession（总入口）

```text
SparkSession = Spark 的"总入口"
  ├── 读数据：spark.read.csv / json / jdbc...
  ├── SQL 查询：spark.sql("...")
  └── 管理临时视图/表
```
> spark-shell 里已自动存在（变量名 `spark`）；正式脚本里要自己创建（Day61）。

## 2. 临时视图

```scala
orders.createOrReplaceTempView("orders")   // DataFrame → 虚拟表
spark.sql("SELECT * FROM orders WHERE ...") // 之后可用 SQL 查
```
- 生命周期：**当前会话**，结束自动消失、不落库
- 踩坑：会话关闭/重启后视图没了（本日实操踩到 TABLE_OR_VIEW_NOT_FOUND）
- 生产启示：交互 shell 只是调试，真实项目用脚本每次从源头重建

## 3. DataFrame API ↔ SQL 对照（复习+深化）

| DataFrame API | SQL |
|---------------|-----|
| df.filter("amount>100") | WHERE amount>100 |
| df.groupBy("status").count() | GROUP BY status + COUNT(*) |
| df.withColumn("x", when(...)) | CASE WHEN ... END AS x |
| df.agg(sum("amount")) | SUM(amount) |

## 4. 实操①：读 CSV 建视图 + SQL 查询

```scala
val orders = spark.read.option("header","true").option("inferSchema","true")
  .csv("/home/vboxuser/py_learn/etl_project/input/biz/biz_order.csv")
orders.createOrReplaceTempView("orders")
spark.sql("SELECT * FROM orders WHERE amount > 100").show()
spark.sql("SELECT status, COUNT(*) AS cnt FROM orders GROUP BY status").show()
spark.sql("SELECT order_date, SUM(amount) AS gmv, COUNT(*) AS order_cnt " +
          "FROM orders WHERE status = 2 GROUP BY order_date ORDER BY order_date").show()
```
GMV 结果与模块四 MySQL 一致：10-10=3117(2)、10-11=6398(2)、10-12=59(1)。

## 5. 实操②：Spark SQL 复现 DWD 清洗 + DWS 汇总

```scala
// DWD 清洗：枚举映射（1未支付/2已支付/3已取消）
spark.sql("""
  SELECT order_id, user_id, product_id, amount, order_date,
         CASE WHEN status = 1 THEN '未支付'
              WHEN status = 2 THEN '已支付'
              ELSE '已取消' END AS status_name
  FROM orders
""").createOrReplaceTempView("dwd_order")

// DWS 用户-日汇总（与 dws_user_daily 同款口径，结果一致）
spark.sql("""
  SELECT user_id, order_date AS stat_date,
         COUNT(*) AS order_cnt, SUM(amount) AS total_amount
  FROM dwd_order WHERE status_name = '已支付'
  GROUP BY user_id, order_date ORDER BY user_id, order_date
""").show()
```

## 6. 实操③：写 CSV + 读写 MySQL

### 写 CSV（coalesce(1) 合并单文件）
```scala
spark.sql("SELECT * FROM dwd_order")
  .coalesce(1).write.mode("overwrite")
  .option("header", "true").csv("/tmp/spark_output/dwd_order_csv")
// 产物：part-00000-*.csv + _SUCCESS（任务完成签名）
```

### 读 MySQL（模块四 dws_user_daily）
```scala
val props = new java.util.Properties()
props.setProperty("user", "root")
props.setProperty("password", "123456")
props.setProperty("driver", "com.mysql.cj.jdbc.Driver")

val dws = spark.read.jdbc(
  "jdbc:mysql://localhost:3306/dw_project?useSSL=false&serverTimezone=Asia/Shanghai",
  "dws_user_daily", props)
dws.show()   // 6 行（含增量 30009）
```

### 写回 MySQL（spark_user_daily 新表）
```scala
val daily = spark.sql("""
  SELECT user_id, order_date AS stat_date,
         COUNT(*) AS order_cnt, SUM(amount) AS total_amount
  FROM dwd_order WHERE status_name = '已支付'
  GROUP BY user_id, order_date
""")
daily.write.mode("overwrite").jdbc(
  "jdbc:mysql://localhost:3306/dw_project?useSSL=false&serverTimezone=Asia/Shanghai",
  "spark_user_daily", props)
```
MySQL 端验证：spark_user_daily 5 行（Spark 从 CSV 8 行计算，不含增量单，与 MySQL 6 行差异合理）。

## 7. Spark 读 MySQL 注意点（面试）

1. **必须挂 JDBC 驱动**（mysql-connector-j jar 放 /opt/spark/jars/，否则 ClassNotFound）
2. 大表加 `partitionColumn` / `numPartitions` 并行读（小表不用）
3. 本地连接串加 `useSSL=false`（避免 SSL 报错）

---

## 今日面试考点清单
1. SparkSession 是什么？→ 总入口（读/查/管视图），shell 里叫 spark
2. 临时视图？→ DataFrame 注册虚拟表供 SQL 用，会话结束消失
3. CASE WHEN ↔ when().otherwise() 等价
4. coalesce(1)？→ 合并单文件，报表交付友好
5. 读 MySQL 注意？→ JDBC 驱动 + 并行参数 + useSSL=false

## 易混淆坑
- 临时视图不跨会话（重开 spark-shell 就没了）
- `! ls` 不是 spark-shell 命令（Scala REPL 不支持 shell 前缀）
- coalesce(1) 是合并分区（文件数），不是过滤数据
- write.mode("overwrite") 覆盖写入，注意别误覆盖
