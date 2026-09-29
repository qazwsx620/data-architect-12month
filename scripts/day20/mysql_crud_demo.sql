#!/bin/bash
# Day20 演示：MySQL 基础 CRUD 初始化脚本（建库/建表/插入/查询/更新/删除）
# 用法：先以 root 进入 mysql，source 本脚本 或 粘贴执行
# 提示：root 需已设置密码，用 mysql -uroot -p 登录后执行

-- 创建库（utf8mb4）
CREATE DATABASE IF NOT EXISTS test_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE test_db;

-- 建表
DROP TABLE IF EXISTS user;
CREATE TABLE user(
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    age TINYINT UNSIGNED,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 插入（指定字段 + 批量）
INSERT INTO user(username,age) VALUES ('zhangsan',20);
INSERT INTO user(username,age) VALUES ('lisi',22),('wangwu',24);

-- 查询
SELECT id,username,age FROM user;
SELECT * FROM user WHERE age > 20;

-- 更新（必须带 WHERE）
UPDATE user SET age=23 WHERE username='lisi';

-- 删除（必须带 WHERE）
DELETE FROM user WHERE username='wangwu';

-- 最终核对
SELECT * FROM user;
