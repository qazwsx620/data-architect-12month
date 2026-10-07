#!/bin/bash
# Day33 演示：窗口函数（排名/累加/LAG/分组TopN）
# 用法：mysql -uroot -p 登录后 source 本脚本
# 依赖：test_db.orders 表（含 user_id/order_no/status/amount/create_time）

USE test_db;

-- 1. 整组求和 vs 逐行累加（对比）
SELECT user_id, order_no, amount,
       SUM(amount) OVER (PARTITION BY user_id) AS group_total,
       SUM(amount) OVER (PARTITION BY user_id ORDER BY create_time, order_id) AS running_total
FROM orders
ORDER BY user_id, create_time;

-- 2. 三个排名函数对比
SELECT user_id, order_no, amount,
       ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn,
       RANK()       OVER (PARTITION BY user_id ORDER BY amount DESC) AS rk,
       DENSE_RANK() OVER (PARTITION BY user_id ORDER BY amount DESC) AS drk
FROM orders;

-- 3. 分组TopN：每个用户金额前2的订单（标准解法）
SELECT user_id, order_no, amount
FROM (
    SELECT user_id, order_no, amount,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
    FROM orders
) t
WHERE t.rn <= 2;

-- 4. LAG 取前一行金额
SELECT user_id, order_no, amount,
       LAG(amount, 1) OVER (PARTITION BY user_id ORDER BY create_time, order_id) AS prev_amount
FROM orders;
