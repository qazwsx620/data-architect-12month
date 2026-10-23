-- Day66 实操①：大数据版订单数仓（odw）四层建仓 DDL
-- 环境说明：本机未装 Hive，此 DDL 纸面落地（语法与 Spark SQL 兼容，装 Hive 后可直接执行）

CREATE DATABASE IF NOT EXISTS odw;

-- ODS：外部表 + 按天分区（保护原始数据，DROP 只删元数据，数据留在 HDFS）
CREATE EXTERNAL TABLE odw.ods_order (
  order_id   BIGINT,
  user_id    BIGINT,
  product_id BIGINT,
  amount     DECIMAL(10,2),
  status     TINYINT
)
PARTITIONED BY (dt STRING)               -- 按天分区：dt=2026-10-10/
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/warehouse/odw/ods_order';

-- DWD：清洗明细（内部表，中间层，枚举映射后可读）
CREATE TABLE odw.dwd_order_detail (
  order_id    BIGINT,
  user_id     BIGINT,
  product_id  BIGINT,
  amount      DECIMAL(10,2),
  status_name STRING,                    -- 1未支付/2已支付/3已取消
  order_date  DATE
)
PARTITIONED BY (dt STRING);

-- DWS：用户-日汇总（已支付口径）
CREATE TABLE odw.dws_user_daily (
  user_id      BIGINT,
  order_cnt    BIGINT,
  total_amount DECIMAL(10,2)
)
PARTITIONED BY (stat_date DATE);

-- DWS：商品-日汇总（已支付口径）
CREATE TABLE odw.dws_product_daily (
  product_id   BIGINT,
  order_cnt    BIGINT,
  total_amount DECIMAL(10,2)
)
PARTITIONED BY (stat_date DATE);

-- ADS：每日 GMV 报表
CREATE TABLE odw.ads_gmv_report (
  stat_date  DATE,
  gmv        DECIMAL(10,2),
  order_cnt  BIGINT,
  avg_amount DECIMAL(10,2)
);
