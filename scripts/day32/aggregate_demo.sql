#!/bin/bash
# Day32 演示：聚合函数 / GROUP BY / HAVING / GROUP_CONCAT / 多字段分组
# 用法：mysql -uroot -p 登录后 source 本脚本
# 依赖：test_db.orders 表（含 user_id/order_no/status/amount）

USE test_db;

-- 0. 准备：给 orders 加金额列并插入测试数据（可重复执行，先清理旧数据）
ALTER TABLE orders ADD COLUMN amount DECIMAL(10,2) DEFAULT 0 COMMENT '订单金额';
DELETE FROM orders;
INSERT INTO orders(user_id,order_no,status,amount) VALUES
(10001,'ORD20260929001',1,99.00),
(10001,'ORD20261001001',1,99.00),
(10001,'ORD20261001002',2,199.00),
(10001,'ORD20261001007',1,49.00),
(10002,'ORD20261001003',1,299.00),
(10002,'ORD20261001004',1,59.00),
(10003,'ORD20261001005',2,399.00),
(10003,'ORD20261001006',1,149.00);

-- 1. 按用户统计订单数与总金额
SELECT user_id, COUNT(*) AS order_cnt, SUM(amount) AS total_amount
FROM orders
GROUP BY user_id;

-- 2. WHERE + GROUP BY + HAVING 组合（状态1的订单，筛出订单数>=2）
SELECT user_id, COUNT(*) AS cnt, SUM(amount) AS total
FROM orders
WHERE status = 1
GROUP BY user_id
HAVING cnt >= 2;

-- 3. GROUP_CONCAT 拼接订单号
SELECT user_id, GROUP_CONCAT(order_no) AS order_list
FROM orders
GROUP BY user_id;

-- 4. 多字段分组
SELECT user_id, status, COUNT(*) AS cnt, SUM(amount) AS total
FROM orders
GROUP BY user_id, status;
