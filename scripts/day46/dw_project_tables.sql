-- ============================================================
-- Day46 订单数仓项目：建库建表 SQL（虚拟机实测通过）
-- 库：dw_project，共 8 表（星型 + 四层）
-- ============================================================

CREATE DATABASE IF NOT EXISTS dw_project DEFAULT CHARACTER SET utf8mb4;
USE dw_project;

-- ---------- 维度表 ----------
CREATE TABLE dim_user (
    user_id   BIGINT PRIMARY KEY,
    user_name VARCHAR(50),
    city      VARCHAR(50),
    reg_date  DATE
);

CREATE TABLE dim_product (
    product_id   BIGINT PRIMARY KEY,
    product_name VARCHAR(100),
    category     VARCHAR(50),
    price        DECIMAL(10,2)
);

-- ---------- 事实表（订单粒度：一单一行）----------
CREATE TABLE fact_order (
    order_id   BIGINT PRIMARY KEY,
    user_id    BIGINT NOT NULL,          -- 外键→dim_user
    product_id BIGINT NOT NULL,          -- 外键→dim_product
    amount     DECIMAL(10,2) NOT NULL,
    status     TINYINT NOT NULL,         -- 1未支付 2已支付 3已取消
    order_date DATE NOT NULL,
    etl_time   DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ---------- ODS 原始层（原样保留，可追溯）----------
CREATE TABLE ods_order (
    order_id   BIGINT PRIMARY KEY,
    user_id    BIGINT,
    product_id BIGINT,
    amount     DECIMAL(10,2),
    status     TINYINT,
    order_date DATE,
    raw_data   VARCHAR(500)   -- 原始行兜底
);

-- ---------- DWD 明细层（清洗规范化）----------
CREATE TABLE dwd_order_detail (
    order_id    BIGINT PRIMARY KEY,
    user_id     BIGINT,
    product_id  BIGINT,
    amount      DECIMAL(10,2),
    status_name VARCHAR(20),   -- 未支付/已支付/已取消
    order_date  DATE
);

-- ---------- DWS 用户日汇总（用户-日粒度）----------
CREATE TABLE dws_user_daily (
    user_id      BIGINT,
    stat_date    DATE,
    order_cnt    INT,
    total_amount DECIMAL(10,2),
    PRIMARY KEY (user_id, stat_date)
);

-- ---------- DWS 商品日汇总（商品-日粒度）----------
CREATE TABLE dws_product_daily (
    product_id   BIGINT,
    stat_date    DATE,
    order_cnt    INT,
    total_amount DECIMAL(10,2),
    PRIMARY KEY (product_id, stat_date)
);

-- ---------- ADS 每日报表（天粒度）----------
CREATE TABLE ads_gmv_report (
    stat_date  DATE PRIMARY KEY,
    gmv        DECIMAL(10,2),   -- 已支付金额合计
    order_cnt  INT,             -- 已支付订单数
    avg_amount DECIMAL(10,2)    -- 客单价 = gmv/order_cnt
);

-- 验证：SHOW TABLES;
-- 预期 8 张：ads_gmv_report / dim_product / dim_user /
--          dwd_order_detail / dws_product_daily / dws_user_daily /
--          fact_order / ods_order
