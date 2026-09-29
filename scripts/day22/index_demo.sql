#!/bin/bash
# Day22 演示：索引原理与执行计划验证（聚簇/二级/覆盖/联合索引）
# 用法：mysql -uroot -p 登录后 source 本脚本
# 重点观察 explain 输出：Using index（覆盖索引）、ALL（全表扫描）、key 列

USE test_db;

-- 1. 建演示表 + 二级索引
DROP TABLE IF EXISTS idx_demo;
CREATE TABLE idx_demo(
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30),
    age INT,
    addr VARCHAR(100)
);
CREATE INDEX idx_name ON idx_demo(name);

INSERT INTO idx_demo(name,age,addr) VALUES
('zhangsan',20,'nanchang'),
('lisi',22,'shanghai');

-- 2. 聚簇索引：主键直接拿到整行
SELECT * FROM idx_demo WHERE id=1;

-- 3. 回表 vs 覆盖索引（看 Extra 列）
EXPLAIN SELECT * FROM idx_demo WHERE name='zhangsan';        -- 回表，Extra 为空
EXPLAIN SELECT id,name FROM idx_demo WHERE name='zhangsan';  -- 覆盖索引，Using index

-- 4. 联合索引最左匹配
CREATE INDEX idx_name_age ON idx_demo(name,age);
EXPLAIN SELECT * FROM idx_demo WHERE name='zhangsan' AND age=20;  -- 走索引
EXPLAIN SELECT * FROM idx_demo WHERE age=20;                      -- 全表扫描 ALL
