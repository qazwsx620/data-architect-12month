// Day60 实操：Spark SQL 全链路（读 CSV → 视图 → 清洗/汇总 → CSV → MySQL 双向）
// 前置：mysql-connector-j jar 已放 /opt/spark/jars/

// ===== 实操①：读 CSV + 建视图 + SQL 查询 =====
val orders = spark.read.option("header", "true").option("inferSchema", "true")
  .csv("/home/vboxuser/py_learn/etl_project/input/biz/biz_order.csv")
orders.createOrReplaceTempView("orders")

spark.sql("SELECT * FROM orders WHERE amount > 100").show()
spark.sql("SELECT status, COUNT(*) AS cnt FROM orders GROUP BY status").show()
spark.sql("SELECT order_date, SUM(amount) AS gmv, COUNT(*) AS order_cnt " +
          "FROM orders WHERE status = 2 GROUP BY order_date ORDER BY order_date").show()

// ===== 实操②：复现 DWD 清洗 + DWS 汇总 =====
spark.sql("""
  SELECT order_id, user_id, product_id, amount, order_date,
         CASE WHEN status = 1 THEN '未支付'
              WHEN status = 2 THEN '已支付'
              ELSE '已取消' END AS status_name
  FROM orders
""").createOrReplaceTempView("dwd_order")
spark.sql("SELECT * FROM dwd_order").show()

spark.sql("""
  SELECT user_id, order_date AS stat_date,
         COUNT(*) AS order_cnt, SUM(amount) AS total_amount
  FROM dwd_order WHERE status_name = '已支付'
  GROUP BY user_id, order_date ORDER BY user_id, order_date
""").show()

// ===== 实操③：写 CSV =====
spark.sql("SELECT * FROM dwd_order")
  .coalesce(1).write.mode("overwrite")
  .option("header", "true").csv("/tmp/spark_output/dwd_order_csv")
// bash 验证: ls -lh /tmp/spark_output/dwd_order_csv/

// ===== 实操③后半：读写 MySQL =====
val props = new java.util.Properties()
props.setProperty("user", "root")
props.setProperty("password", "123456")
props.setProperty("driver", "com.mysql.cj.jdbc.Driver")
val url = "jdbc:mysql://localhost:3306/dw_project?useSSL=false&serverTimezone=Asia/Shanghai"

// 读 MySQL（模块四 dws_user_daily）
val dws = spark.read.jdbc(url, "dws_user_daily", props)
dws.show()

// Spark 计算结果写回 MySQL 新表
val daily = spark.sql("""
  SELECT user_id, order_date AS stat_date,
         COUNT(*) AS order_cnt, SUM(amount) AS total_amount
  FROM dwd_order WHERE status_name = '已支付'
  GROUP BY user_id, order_date
""")
daily.write.mode("overwrite").jdbc(url, "spark_user_daily", props)
// MySQL 验证: mysql -uroot -p123456 dw_project -e "SELECT * FROM spark_user_daily ORDER BY user_id;"
