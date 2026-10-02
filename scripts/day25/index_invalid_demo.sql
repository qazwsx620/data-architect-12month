#!/bin/bash
# Day25 演示：索引失效场景 explain 验证（函数/隐式转换/like/or/负向查询）
# 用法：mysql -uroot -p 登录后 source 本脚本
# 重点观察：type=ALL 全表扫描（索引失效） vs range/ref（走索引）

USE test_db;

-- 准备：user 表加 username 索引、age 索引
CREATE INDEX idx_user_username ON user(username);
CREATE INDEX idx_user_age ON user(age);

-- 1. 函数/运算导致失效
EXPLAIN SELECT * FROM user WHERE age+1=21;   -- ALL 失效
EXPLAIN SELECT * FROM user WHERE age=20;     -- ref 走索引

-- 2. 隐式类型转换（模拟：phone 字段场景）
-- user 表无 phone 字段时以下语句仅作语法演示，可自行建 char 字段验证
-- EXPLAIN SELECT * FROM user WHERE phone=13800138000;     -- ALL 失效
-- EXPLAIN SELECT * FROM user WHERE phone='13800138000';   -- 走索引

-- 3. like 前缀匹配
EXPLAIN SELECT * FROM user WHERE username LIKE 'zhang%';   -- range 走索引
EXPLAIN SELECT * FROM user WHERE username LIKE '%zhang';   -- ALL 失效

-- 4. or 条件（一侧无索引 / 都有索引）
EXPLAIN SELECT * FROM user WHERE username='zhangsan' OR age=20;

-- 5. 负向查询（观察是否走索引）
EXPLAIN SELECT * FROM user WHERE username != 'zhangsan';
