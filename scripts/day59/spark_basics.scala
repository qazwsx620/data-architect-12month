// Day59 实操②③：Spark Shell 读写数据 + DataFrame 基础操作 + DWD 清洗/GMV 复现
// 进入方式：spark-shell（local 单机模式）

// ===== 实操②：内存数据 → DataFrame =====
val df = Seq(
  (30001, 1001, 2999.00, "已支付"),
  (30002, 1002, 99.00,   "未支付"),
  (30003, 1003, 118.00,  "已支付")
).toDF("order_id", "user_id", "amount", "status_name")
df.show()

// 读真实业务 CSV（inferSchema 自动推断类型）
val orders = spark.read.option("header", "true").option("inferSchema", "true")
  .csv("/home/vboxuser/py_learn/etl_project/input/biz/biz_order.csv")
orders.show()
orders.printSchema()

// 基础操作：筛选 + 分组统计
orders.filter("amount > 100").show()
orders.groupBy("status").count().show()

// ===== 实操③：Spark 版 DWD 清洗 + GMV 复现（连接模块四） =====
import org.apache.spark.sql.functions._

// 枚举映射：1未支付 / 2已支付 / 3已取消
val dwd = orders.withColumn("status_name",
  when(col("status") === 1, "未支付")
  .when(col("status") === 2, "已支付")
  .otherwise("已取消"))
dwd.select("order_id", "user_id", "amount", "status_name").show()

// GMV 口径：只算已支付
val gmv = dwd.filter("status_name = '已支付'")
  .agg(sum("amount").as("gmv"), count("order_id").as("order_cnt"))
gmv.show()

// 每日 GMV（对应 DWS 汇总）
val daily = dwd.filter("status_name = '已支付'")
  .groupBy("order_date")
  .agg(sum("amount").as("gmv"), count("order_id").as("order_cnt"))
  .orderBy("order_date")
daily.show()
