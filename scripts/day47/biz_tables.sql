-- ============================================================
-- Day47：业务源表 + ODS 表准备 SQL（虚拟机实测通过）
-- 前置：config.py 增加 DW_CONFIG 指向 dw_project
-- ============================================================

USE dw_project;

-- ---------- 业务源表（模拟业务库）----------
CREATE TABLE IF NOT EXISTS biz_user (
    user_id   BIGINT PRIMARY KEY,
    user_name VARCHAR(50),
    city      VARCHAR(50),
    reg_date  DATE
);

CREATE TABLE IF NOT EXISTS biz_product (
    product_id   BIGINT PRIMARY KEY,
    product_name VARCHAR(100),
    category     VARCHAR(50),
    price        DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS biz_order (
    order_id  BIGINT PRIMARY KEY,
    user_id   BIGINT,
    product_id BIGINT,
    amount    DECIMAL(10,2),
    status    TINYINT,
    order_date DATE
);

-- ODS 表补列（Day46 建表无 etl_time，脚本需要）
ALTER TABLE ods_order ADD COLUMN etl_time DATETIME DEFAULT CURRENT_TIMESTAMP;

-- ---------- 导入 CSV（需客户端 --local-infile=1）----------
-- LOAD DATA LOCAL INFILE '/home/vboxuser/py_learn/etl_project/input/biz/biz_user.csv'
-- INTO TABLE biz_user FIELDS TERMINATED BY ',' IGNORE 1 LINES;
-- LOAD DATA LOCAL INFILE '/home/vboxuser/py_learn/etl_project/input/biz/biz_product.csv'
-- INTO TABLE biz_product FIELDS TERMINATED BY ',' IGNORE 1 LINES;
-- LOAD DATA LOCAL INFILE '/home/vboxuser/py_learn/etl_project/input/biz/biz_order.csv'
-- INTO TABLE biz_order FIELDS TERMINATED BY ',' IGNORE 1 LINES;

-- 模拟新增订单（验证增量）
-- INSERT INTO biz_order VALUES (30009, 1007, 2005, 399.00, 2, '2026-10-13');

-- 验证
-- SELECT COUNT(*) FROM biz_user;    -- 10
-- SELECT COUNT(*) FROM biz_product; -- 5
-- SELECT COUNT(*) FROM biz_order;   -- 8
