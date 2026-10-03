#!/bin/bash
# Day28 演示：MVCC 机制验证（快照读/当前读/事务ID查看）
# 用法：mysql -uroot -p 登录后执行（涉及双会话实验时开启两个终端）

USE test_db;

-- 1. 快照读（普通 SELECT，不加锁）
BEGIN;
SELECT * FROM account WHERE name='张三';

-- 2. 当前读（FOR UPDATE 加锁，读最新数据）
SELECT * FROM account WHERE name='张三' FOR UPDATE;
COMMIT;

-- 3. 修改产生新版本 + 查看运行中事务
BEGIN;
UPDATE account SET balance=900 WHERE name='张三';
SELECT trx_id, trx_state FROM information_schema.innodb_trx WHERE trx_state='RUNNING';
COMMIT;

-- 4. 收尾检查：确认无残留事务
SELECT trx_id, trx_state FROM information_schema.innodb_trx;
