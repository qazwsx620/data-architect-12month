#!/bin/bash
# Day27 演示：事务隔离级别并发实验（脏读/不可重复读/可重复读）
# 用法：需要开启两个 mysql 会话（终端A、终端B），按注释步骤在两终端分别执行
# 实验表：account（张三/李四）

-- ============ 0. 准备 ============
-- 两终端都执行：
USE test_db;
SELECT @@transaction_isolation;   -- 确认默认 REPEATABLE-READ
-- 复位张三余额为 800：
UPDATE account SET balance=800 WHERE name='张三'; COMMIT;

-- ============ 1. 脏读实验 ============
-- 终端A（保持 REPEATABLE READ）：
BEGIN;
UPDATE account SET balance=500 WHERE name='张三';   -- 不提交

-- 终端B（默认 RR，应读 800）：
SELECT * FROM account WHERE name='张三';
-- 终端B 改为读未提交：
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM account WHERE name='张三';   -- 读到 500，脏读发生

-- 收尾：
-- 终端A：ROLLBACK;
-- 终端B：SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- ============ 2. 不可重复读实验（READ COMMITTED）============
-- 终端B：
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;
SELECT * FROM account WHERE name='张三';   -- 第一次读
-- 终端A（RR）：
UPDATE account SET balance=300 WHERE name='张三'; COMMIT;
-- 终端B 第二次读（预期 300，若之前为 800 则不一致 → 不可重复读）
SELECT * FROM account WHERE name='张三';
-- 终端B：COMMIT;

-- ============ 3. 可重复读实验（REPEATABLE READ）============
-- 终端B：
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
SELECT * FROM account WHERE name='张三';   -- 第一次读
-- 终端A：
UPDATE account SET balance=200 WHERE name='张三'; COMMIT;
-- 终端B 第二次读（预期与第一次一致 → 可重复读）
SELECT * FROM account WHERE name='张三';
-- 终端B：COMMIT;
