// Day61 实操：Catalyst 观察 + 广播/Shuffle JOIN 对比 + 窗口函数 + ADS 复现
// 前置：进入 spark-shell 后先建视图

val orders = spark.read.option("header", "true").option("inferSchema", "true")
  .csv("/home/vboxuser/py_learn/etl_project/input/biz/biz_order.csv")
orders.createOrReplaceTempView("orders")

// ===== 实操③：explain 观察谓词下推 =====
spark.sql("""
  SELECT order_date, SUM(amount) AS gmv
  FROM orders WHERE status = 2
  GROUP BY order_date
""").explain()
// 看：Filter 在 HashAggregate 前；FileScan 的 PushedFilters 下推

// ===== 实操②：广播 JOIN vs Shuffle JOIN =====
val users = Seq((1001,"张三"),(1002,"李四"),(1003,"王五"))
  .toDF("user_id","user_name")
users.createOrReplaceTempView("dim_user_small")

// ① 默认：小表自动广播 → BroadcastHashJoin（BuildRight）
spark.sql("""
  SELECT o.order_id, u.user_name, o.amount
  FROM orders o JOIN dim_user_small u ON o.user_id = u.user_id
""").explain()

// ② 关闭自动广播（阈值 -1）→ SortMergeJoin + Exchange（Shuffle JOIN）
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")
spark.sql("""
  SELECT o.order_id, u.user_name, o.amount
  FROM orders o JOIN dim_user_small u ON o.user_id = u.user_id
""").explain()
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "10")

// ===== 实操①：窗口函数 TopN + ADS 复现 =====
spark.sql("""
  SELECT user_id, order_id, amount, rn FROM (
    SELECT user_id, order_id, amount,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
    FROM orders
  ) t WHERE rn <= 2 ORDER BY user_id, rn
""").show()

spark.sql("""
  SELECT order_date AS stat_date,
         SUM(CASE WHEN status = 2 THEN amount ELSE 0 END) AS gmv,
         COUNT(CASE WHEN status = 2 THEN 1 END)           AS order_cnt,
         ROUND(SUM(CASE WHEN status = 2 THEN amount ELSE 0 END) /
               COUNT(CASE WHEN status = 2 THEN 1 END), 2) AS avg_amount
  FROM orders
  GROUP BY order_date ORDER BY order_date
""").show()
