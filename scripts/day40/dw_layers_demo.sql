-- Day40 演示：数仓分层建表 + 星型模型
-- 用法：mysql -uroot -p 登录后 source 本脚本
USE test_db;

-- ====== 1. 数仓四层 ======
-- ODS：原始数据层（原样存储）
CREATE TABLE IF NOT EXISTS ods_order (
    order_id   BIGINT PRIMARY KEY,
    user_id    BIGINT,
    order_no   VARCHAR(32),
    amount     DECIMAL(10,2),
    status     TINYINT,
    create_time DATETIME
);

-- DWD：明细数据层（清洗、规范化）
CREATE TABLE IF NOT EXISTS dwd_order_detail (
    order_id   BIGINT PRIMARY KEY,
    user_id    BIGINT,
    order_no   VARCHAR(32),
    amount     DECIMAL(10,2),
    status     TINYINT,
    status_name VARCHAR(20) COMMENT '1-正常 2-退款',
    create_time DATETIME
);

-- DWS：汇总数据层（按用户+日期轻度汇总）
CREATE TABLE IF NOT EXISTS dws_user_daily (
    stat_date   DATE,
    user_id     BIGINT,
    order_cnt   INT,
    amount_sum  DECIMAL(12,2),
    PRIMARY KEY (stat_date, user_id)
);

-- ADS：应用数据层（业务报表）
CREATE TABLE IF NOT EXISTS ads_user_report (
    user_id     BIGINT PRIMARY KEY,
    total_cnt   INT,
    total_amount DECIMAL(12,2)
);

-- ====== 2. 星型模型 ======
-- 维度表1：用户维度
CREATE TABLE IF NOT EXISTS dim_user (
    user_id   BIGINT PRIMARY KEY,
    user_name VARCHAR(50),
    city      VARCHAR(50)
);

-- 维度表2：商品维度
CREATE TABLE IF NOT EXISTS dim_product (
    product_id  BIGINT PRIMARY KEY,
    product_name VARCHAR(100),
    category    VARCHAR(50)
);

-- 事实表：订单事实（外键引用维度表）
CREATE TABLE IF NOT EXISTS fact_order (
    order_id   BIGINT PRIMARY KEY,
    user_id    BIGINT,
    product_id BIGINT,
    amount     DECIMAL(10,2),
    create_time DATETIME,
    FOREIGN KEY (user_id) REFERENCES dim_user(user_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
);

-- 查看结果
SHOW TABLES;
