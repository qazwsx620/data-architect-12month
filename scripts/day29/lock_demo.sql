#!/bin/bash
# Day29 演示：InnoDB 锁机制（行锁阻塞/间隙锁/死锁复现）
# 用法：需要两个 mysql 会话（终端A、终端B），按注释步骤分别执行
# 实验表：account（id=1 张三、id=2 李四）

-- ============ 1. X锁阻塞当前读 ============
-- 终端A：
BEGIN;
SELECT * FROM account WHERE name='张三' FOR UPDATE;   -- 持X锁
-- 终端B：普通快照读（应立即返回）
SELECT * FROM account WHERE name='张三';
-- 终端B：当前读（应卡住等待）
SELECT * FROM account WHERE name='张三' FOR UPDATE;
-- 终端A：COMMIT;  -- 释放后 B 的 FOR UPDATE 返回

-- ============ 2. 间隙锁防插入（可选） ============
-- 终端A：
BEGIN;
SELECT * FROM account WHERE id > 1 FOR UPDATE;   -- 触发间隙锁
-- 终端B：插入 id=3 会被阻塞
-- INSERT INTO account(id,name,balance) VALUES (3,'测试',500);
-- 终端A：COMMIT;

-- ============ 3. 死锁复现 ============
-- 终端A：
BEGIN;
UPDATE account SET balance=balance-10 WHERE id=1;   -- A持有行1锁
-- 终端B：
BEGIN;
UPDATE account SET balance=balance-10 WHERE id=2;   -- B持有行2锁
-- 终端A：尝试更新行2（等B释放，等待中）
UPDATE account SET balance=balance-10 WHERE id=2;
-- 终端B：尝试更新行1 → 死锁！报 ERROR 1213，B被回滚
UPDATE account SET balance=balance-10 WHERE id=1;

-- 收尾：两终端 COMMIT; 并检查残留事务
-- SELECT trx_id, trx_state FROM information_schema.innodb_trx;
