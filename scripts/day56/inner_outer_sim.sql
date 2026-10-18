-- Day56 实操①：内部表 vs 外部表 DROP 行为模拟（MySQL）
-- 普通表 ≈ Hive 内部表（DROP 数据全没）；视图 ≈ Hive 外部表（DROP 只删壳，数据保留）

USE test_db;

-- ===== 模拟内部表：普通表 =====
CREATE TABLE inner_like (id INT, name VARCHAR(20));
INSERT INTO inner_like VALUES (1,'a'),(2,'b');
DROP TABLE inner_like;          -- 表+数据全删

-- ===== 模拟外部表：视图（壳=元数据，基表=数据） =====
CREATE TABLE base_data (id INT, name VARCHAR(20));
INSERT INTO base_data VALUES (1,'x'),(2,'y');
CREATE VIEW outer_like AS SELECT * FROM base_data;
DROP VIEW outer_like;           -- 只删壳
SELECT * FROM base_data;        -- 数据还在！→ 类比外部表 DROP 后 HDFS 数据保留
