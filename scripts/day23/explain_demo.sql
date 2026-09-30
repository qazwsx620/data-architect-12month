#!/bin/bash
# Day23 演示：explain 执行计划逐场景验证（ref/range/ALL/filesort/temporary/覆盖索引）
# 用法：mysql -uroot -p 登录后 source 本脚本
# 重点观察：type 列级别、key 列是否走索引、Extra 列坏信号

USE test_db;

-- 1. 准备演示表与索引
DROP TABLE IF EXISTS idx_demo;
CREATE TABLE idx_demo(
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30),
    age INT,
    addr VARCHAR(100)
);
CREATE INDEX idx_name ON idx_demo(name);
CREATE INDEX idx_age ON idx_demo(age);
CREATE INDEX idx_name_age ON idx_demo(name,age);

INSERT INTO idx_demo(name,age,addr) VALUES
('zhangsan',20,'nanchang'),
('lisi',22,'shanghai');

-- 2. ref：普通索引等值匹配
EXPLAIN SELECT * FROM idx_demo WHERE name='zhangsan';

-- 3. range：范围查询走索引
EXPLAIN SELECT * FROM idx_demo WHERE age>20;

-- 4. ALL：全表扫描（无索引可用）
EXPLAIN SELECT * FROM idx_demo WHERE addr='nanchang';

-- 5. filesort：order by 无可用索引
EXPLAIN SELECT * FROM idx_demo ORDER BY addr;

-- 6. 覆盖索引消除 filesort
EXPLAIN SELECT age FROM idx_demo ORDER BY age;

-- 7. group by 临时表对比（有 idx_age 时走索引）
EXPLAIN SELECT age,count(*) FROM idx_demo GROUP BY age;
