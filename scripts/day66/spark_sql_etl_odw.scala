// Day66 实操②：Spark SQL 四层 ETL（ODS→DWD→DWS→ADS，真实执行）
// 用法：spark-shell 内逐段执行
// 结果与模块四 ads_gmv_report 一致：3117 / 6398 / 59

// ===== ODS 层：读业务 CSV → 视图 =====
val ods = spark.read.option("header", "true").option("inferSchema", "true")
  .csv("/home/vboxuser/py_learn/etl_project/input/biz/biz_order.csv")
ods.createOrReplaceTempView("ods_order")

// ===== DWD 层：清洗（枚举映射） =====
spark.sql("""
  SELECT order_id, user_id, product_id, amount,
         CASE WHEN status = 1 THEN '未支付'
              WHEN status = 2 THEN '已支付'
              ELSE '已取消' END AS status_name,
         order_date
  FROM ods_order
""").createOrReplaceTempView("dwd_order_detail")

// ===== DWS 层：用户-日汇总（已支付口径） =====
spark.sql("""
  SELECT user_id, order_date AS stat_date,
         COUNT(*) AS order_cnt, SUM(amount) AS total_amount
  FROM dwd_order_detail
  WHERE status_name = '已支付'
  GROUP BY user_id, order_date
""").createOrReplaceTempView("dws_user_daily")

// ===== ADS 层：每日 GMV 报表 =====
spark.sql("""
  SELECT stat_date,
         SUM(total_amount) AS gmv,
         SUM(order_cnt)    AS order_cnt,
         ROUND(SUM(total_amount) / SUM(order_cnt), 2) AS avg_amount
  FROM dws_user_daily
  GROUP BY stat_date
  ORDER BY stat_date
""").show()
