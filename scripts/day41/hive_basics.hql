-- Day41 演示：Hive 基础 HQL（环境受限，纸面练习）
-- 说明：以下为 Hive HQL 语法，可在 Hive/Spark SQL 环境执行；虚拟机上用 MySQL 做等价理解。

-- ====== 1. 内部表 vs 外部表 ======
-- 内部表：删表时元数据 + 数据一起删
CREATE TABLE t_internal (id BIGINT);

-- 外部表：删表只删元数据，数据保留（挂业务方数据）
CREATE EXTERNAL TABLE t_external (id BIGINT)
LOCATION '/data/ods/xxx';

-- ====== 2. 分区表 ======
-- 按天分区：查询只扫需要的分区（分区裁剪）
CREATE TABLE dwd_order_detail (
    order_id BIGINT,
    user_id  BIGINT,
    amount   DECIMAL(10,2),
    status   TINYINT
)
PARTITIONED BY (dt STRING)                          -- 分区字段
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';     -- 数据 tab 分隔

-- 分区裁剪查询：只扫 2026-10-09 分区
SELECT user_id, SUM(amount)
FROM dwd_order_detail
WHERE dt = '2026-10-09'
GROUP BY user_id;

-- ====== 3. 综合练习：外部表 + 分区表 ======
CREATE EXTERNAL TABLE ods_user_log(
    user_id BIGINT,
    action  STRING
)
PARTITIONED BY (dt STRING)
LOCATION '/data/ods/user_log';

-- 每天每个用户每个动作的次数
SELECT dt, user_id, action, COUNT(*) AS cnt
FROM ods_user_log
GROUP BY dt, user_id, action;
