#!/bin/bash
# Day26 演示：事务控制与 ACID 验证（回滚/转账原子性与一致性）
# 用法：mysql -uroot -p 登录后 source 本脚本

USE test_db;

-- 1. 回滚撤销未提交插入（原子性）
BEGIN;
INSERT INTO user(username,age) VALUES ('rollback_test',40);
SELECT * FROM user WHERE username='rollback_test';   -- 事务内可见
ROLLBACK;
SELECT * FROM user WHERE username='rollback_test';   -- 已消失

-- 2. 转账场景（一致性：总金额不变）
CREATE TABLE IF NOT EXISTS account(
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30),
    balance INT
);
DELETE FROM account;
INSERT INTO account(name,balance) VALUES ('张三',1000),('李四',1000);

-- 正常转账
BEGIN;
UPDATE account SET balance=balance-200 WHERE name='张三';
UPDATE account SET balance=balance+200 WHERE name='李四';
COMMIT;
SELECT * FROM account;   -- 张三 800 / 李四 1200

-- 出错回滚（第二步无匹配行）
BEGIN;
UPDATE account SET balance=balance-200 WHERE name='张三';
UPDATE account SET balance=balance+200 WHERE name='李四2';
ROLLBACK;
SELECT * FROM account;   -- 张三扣款被撤销，恢复 800
