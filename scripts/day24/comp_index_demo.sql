#!/bin/bash
# Day24 演示：联合索引最左前缀 / 范围截断 / 排序优化 explain 验证
# 用法：mysql -uroot -p 登录后 source 本脚本

USE test_db;

-- 1. 建表 + 联合索引
DROP TABLE IF EXISTS comp_idx_demo;
CREATE TABLE comp_idx_demo(
    id INT PRIMARY KEY AUTO_INCREMENT,
    a INT,
    b INT,
    c INT
);
CREATE INDEX idx_a_b_c ON comp_idx_demo(a,b,c);

INSERT INTO comp_idx_demo(a,b,c) VALUES
(1,1,1),
(1,2,2),
(2,1,3),
(2,2,4);

-- 2. 等值连续匹配（ref，命中）
EXPLAIN SELECT * FROM comp_idx_demo WHERE a=1 AND b=2;

-- 3. 跳过最左字段（index 索引全扫描）
EXPLAIN SELECT * FROM comp_idx_demo WHERE b=2;

-- 4. 范围截断（a、b 走索引，c 失效）
EXPLAIN SELECT * FROM comp_idx_demo WHERE a=1 AND b>2 AND c=3;

-- 5. 排序优化对比
EXPLAIN SELECT a,b FROM comp_idx_demo WHERE a=1 ORDER BY b;  -- 无 filesort
EXPLAIN SELECT a,c FROM comp_idx_demo WHERE a=1 ORDER BY c;  -- Using filesort
