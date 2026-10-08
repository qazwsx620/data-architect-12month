#!/bin/bash
# Day34 演示：子查询（标量/列/表）与 CTE
# 用法：mysql -uroot -p 登录后 source 本脚本
# 依赖：test_db.orders（user_id/order_no/amount）、user_main（id/username）

USE test_db;

-- 1. 标量子查询：金额高于平均值的订单
SELECT order_no, amount
FROM orders
WHERE amount > (SELECT AVG(amount) FROM orders);

-- 2. 列子查询：有订单的用户
SELECT id FROM user_main WHERE id IN (SELECT user_id FROM orders);

-- 3. 表子查询：分组TopN（必须起别名）
SELECT user_id, order_no, amount
FROM (
    SELECT user_id, order_no, amount,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
    FROM orders
) t
WHERE t.rn <= 2;

-- 4. IN vs EXISTS 执行计划对比
EXPLAIN SELECT id FROM user_main WHERE id IN (SELECT user_id FROM orders);
EXPLAIN SELECT id FROM user_main u WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);

-- 5. CTE 版 TopN
WITH ranked AS (
    SELECT user_id, order_no, amount,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
    FROM orders
)
SELECT user_id, order_no, amount FROM ranked WHERE rn <= 2;

-- 6. 多 CTE 层层递进
WITH
user_orders AS (SELECT user_id, COUNT(*) AS cnt FROM orders GROUP BY user_id),
high_users  AS (SELECT user_id FROM user_orders WHERE cnt >= 2)
SELECT * FROM high_users;
