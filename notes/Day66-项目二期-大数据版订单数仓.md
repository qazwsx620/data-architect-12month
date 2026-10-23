# Day66 · 项目二期：大数据版订单数仓（四层建仓 + Spark SQL ETL + 全链路设计）

> 模块五 · 大数据数仓进阶 Day11（收官主项目）| 配套脚本见 `scripts/day66/`。
> 真实环境：Spark 3.5.1 真实执行四层 ETL；Hive 未装，DDL 纸面落地（与 Spark SQL 兼容）。

---

## 1. 单机数仓 → 大数据迁移关键点（面试必答）

| 维度 | 模块四（单机） | 模块五（大数据版 odw） |
|------|---------------|----------------------|
| 存储 | MySQL 单机表 | HDFS 分布式（分区目录） |
| 计算 | Pandas/MySQL SQL | Spark SQL / Hive |
| 建表 | MySQL DDL | Hive DDL（外部表+分区） |
| 调度 | crontab + etl_chain.py | crontab / Airflow（思想复用） |
| 质量 | quality_check.py | quality_engine.py（规则配置化，复用） |
| 血缘/字典 | lineage.md / data_dictionary.md | 直接复用 |

> 面试一句话：**分层/口径/幂等不变，只换存储和计算引擎**——业务逻辑一套，MySQL 换 Hive/Spark 而已。

## 2. 实操①：Hive 四层建仓 DDL（odw 库）

```sql
-- ODS：外部表 + 按天分区（保护原始数据，DROP 只删元数据）
CREATE EXTERNAL TABLE odw.ods_order (
  order_id BIGINT, user_id BIGINT, product_id BIGINT,
  amount DECIMAL(10,2), status TINYINT
) PARTITIONED BY (dt STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE LOCATION '/warehouse/odw/ods_order';

-- DWD 清洗明细（内部表，status_name 可读）、DWS 用户/商品日汇总（stat_date 分区）、ADS 报表
```
完整见 `odw_create_tables.sql`。

## 3. 实操②：Spark SQL 四层 ETL（真实执行）

```scala
// ODS：读业务 CSV → 视图
spark.read.option("header","true").option("inferSchema","true")
  .csv("/home/vboxuser/py_learn/etl_project/input/biz/biz_order.csv")
  .createOrReplaceTempView("ods_order")

// DWD：清洗（CASE 枚举映射 1未支付/2已支付/3已取消）
spark.sql("""SELECT order_id,user_id,product_id,amount,
  CASE WHEN status=1 THEN '未支付' WHEN status=2 THEN '已支付' ELSE '已取消' END AS status_name,
  order_date FROM ods_order""").createOrReplaceTempView("dwd_order_detail")

// DWS：用户-日汇总（已支付口径）
spark.sql("""SELECT user_id,order_date AS stat_date,
  COUNT(*) AS order_cnt, SUM(amount) AS total_amount
  FROM dwd_order_detail WHERE status_name='已支付'
  GROUP BY user_id,order_date""").createOrReplaceTempView("dws_user_daily")

// ADS：每日 GMV 报表
spark.sql("""SELECT stat_date, SUM(total_amount) AS gmv,
  SUM(order_cnt) AS order_cnt, ROUND(SUM(total_amount)/SUM(order_cnt),2) AS avg_amount
  FROM dws_user_daily GROUP BY stat_date ORDER BY stat_date""").show()
```

**结果与模块四 ads_gmv_report 完全一致**：3117/6398/59 —— 分层/口径/幂等不变，只换引擎。

## 4. 实操③：全链路设计（纸面，odw_design.md）

- **调度**：crontab 每天 02:00 跑 odw_etl.sh，失败退出非0阻断下游（同模块四 rerun.sh）
- **质量**：复用 Day65 quality_engine.py（rules.yaml 加 odw 表规则，DWD→DWS 之间插校验，FAIL 阻断）
- **血缘/字典**：lineage.md 加 Hive 层；data_dictionary.md 加 odw 分层说明，口径不变
- **可复用四件套**：调度 / 质量 / 血缘 / 字典

---

## 今日面试考点清单
1. 迁移变什么不变什么？→ 只换存储/计算引擎，分层/口径/幂等不变
2. ODS 外部表？→ 保护原始数据不被误删
3. 分区好处？→ 查询裁剪 + 增量装载（目录级）
4. 结果一致？→ 一致，只是换方言
5. 复用组件？→ 调度/质量/血缘/字典四件套

## 易混淆坑
- 外部表 DROP 只删元数据，数据还在 HDFS（Day56 深化）
- DWS 分区字段 stat_date vs ODS 分区字段 dt——按粒度选
- 临时视图不跨会话（重开 shell 要重跑 ODS 装载）
- Hive 未装时 DDL 纸面落地 + Spark SQL 真实执行同逻辑 = 不降级
