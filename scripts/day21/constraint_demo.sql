#!/bin/bash
# Day21 演示：MySQL 数据类型与约束练习脚本
# 用法：mysql -uroot -p 登录后 source 本脚本
# 提示：脚本使用 utf8mb4 库，root 密码在命令行交互输入

CREATE DATABASE IF NOT EXISTS test_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE test_db;

-- 1. 数据类型演示表
CREATE TABLE IF NOT EXISTS type_demo(
    id INT PRIMARY KEY AUTO_INCREMENT,
    age TINYINT UNSIGNED,
    phone CHAR(11),
    username VARCHAR(50),
    create_time DATETIME
);

-- 2. 约束演示：订单表（主键/非空/唯一/默认）
CREATE TABLE IF NOT EXISTS orders (
    order_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '订单主键',
    user_id BIGINT NOT NULL COMMENT '用户id',
    order_no VARCHAR(32) UNIQUE NOT NULL COMMENT '订单编号，唯一',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '订单状态，默认1正常',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
);

-- 3. 正常插入
INSERT INTO orders(user_id,order_no) VALUES (10001,'ORD20260929001');

-- 4. 下面两行会报错，验证约束：
-- INSERT INTO orders(user_id,order_no) VALUES (10001,'ORD20260929001');  -- 唯一冲突
-- INSERT INTO orders(order_no) VALUES ('ORD20260929002');                -- 非空缺失

-- 5. 外键演示（InnoDB，了解原理，业务不推荐）
CREATE TABLE IF NOT EXISTS user_main(
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户主键',
    username VARCHAR(50) NOT NULL
);
CREATE TABLE IF NOT EXISTS order_fk(
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_name VARCHAR(50),
    uid BIGINT,
    FOREIGN KEY (uid) REFERENCES user_main(id)
);
-- 下面这行会报错：主表无 id=9999
-- INSERT INTO order_fk(order_name,uid) VALUES ('test订单',9999);

-- 6. NULL 查询对比（= NULL 恒空，IS NULL 正确）
SELECT * FROM orders WHERE status = NULL;
SELECT * FROM orders WHERE status IS NULL;
