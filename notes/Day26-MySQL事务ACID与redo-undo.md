# Day26 · MySQL 事务 ACID 与 redo/undo（事务控制 / 崩溃恢复 / WAL）

> 阶段01 · 第2月 | 配套脚本见 `scripts/day26/` 目录，虚拟机实测通过。
> 背景：事务是 MySQL 高可靠性基石，ACID 实现机制是面试必考重灾区。

---

## 1. 事务概念

事务：一组 SQL 要么全部成功，要么全部失败，不可分割。
经典场景：转账（A 扣款 1000 + B 到账 1000 必须同时成功/失败）。

## 2. 四大特性 ACID（面试必背）

| 特性 | 含义 | 实现机制 |
|------|------|----------|
| **A 原子性** | 全部执行或全部不执行，无中间状态 | undo log（回滚日志） |
| **C 一致性** | 事务前后数据满足完整性约束 | 最终目标 |
| **I 隔离性** | 并发事务互不干扰 | 锁 + MVCC |
| **D 持久性** | 提交后永久保存，崩溃不丢失 | redo log（重做日志） |

## 3. 事务控制命令（实操）

```sql
BEGIN;                                -- 开始事务（或 START TRANSACTION）
INSERT INTO user(username,age) VALUES ('tran_test',30);
COMMIT;                               -- 提交，永久生效
ROLLBACK;                             -- 回滚，撤销未提交的修改
```

> ⚠️【坑】COMMIT 之后事务已结束，ROLLBACK 无效；必须先 ROLLBACK 再 COMMIT 才有效。
> 事务内修改在 ROLLBACK 后全部撤销（原子性体现）。

## 4. redo log（重做日志）——保证持久性

- 记录**物理修改**：哪个页、哪一行、改成什么
- 事务提交时先把 redo log 写入磁盘（顺序写，快），数据页稍后异步刷盘
- 崩溃恢复：重放 redo log，恢复**已提交事务**的数据

**WAL（Write-Ahead Logging）**：先写日志，再写数据，保证崩溃安全。

## 5. undo log（回滚日志）——保证原子性

- 记录**逻辑逆操作**：修改前的旧值
- 事务回滚：把数据恢复成修改前状态
- 也用于 MVCC 多版本控制

## 6. redo vs undo 对比

| | redo log | undo log |
|--|----------|----------|
| 作用 | 崩溃恢复，持久性 | 回滚恢复，原子性 |
| 记录 | 修改后的新值（物理） | 修改前的旧值（逻辑） |
| 恢复对象 | 已提交事务 | 未提交事务 |
| 写入时机 | 提交时写 | 修改时写 |

## 7. 转账场景（实操验证）

```sql
CREATE TABLE account(id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(30), balance INT);
INSERT INTO account(name,balance) VALUES ('张三',1000),('李四',1000);

-- 正常转账
BEGIN;
UPDATE account SET balance=balance-200 WHERE name='张三';
UPDATE account SET balance=balance+200 WHERE name='李四';
COMMIT;
-- 结果：张三 800，李四 1200，总金额不变（一致性）

-- 出错回滚（第二步无匹配行或报错）
BEGIN;
UPDATE account SET balance=balance-200 WHERE name='张三';
UPDATE account SET balance=balance+200 WHERE name='李四2';  -- 无匹配
ROLLBACK;
-- 结果：张三扣款被撤销（原子性）
```

> ⚠️ SQL 报错不会自动回滚，需程序捕获异常后主动 ROLLBACK。

---

## 今日面试考点清单
1. ACID 分别靠什么实现？→ 原子性 undo、持久性 redo、隔离性锁+MVCC、一致性目标
2. COMMIT/ROLLBACK 作用？COMMIT 后可 ROLLBACK？→ 提交/撤销；不能
3. redo 与 undo 区别？→ 重做已提交 vs 回滚未提交；物理新值 vs 逻辑旧值
4. 什么是 WAL？→ 先写日志再写数据，崩溃安全
5. 转账第二步报错怎么办？→ ROLLBACK 保证原子性
6. 崩溃恢复用哪个日志？→ 已提交用 redo 重放

## 踩坑记录（面试素材）
- COMMIT 后 ROLLBACK 无效 → 事务已结束
- 以为 SQL 报错自动回滚 → 需手动 ROLLBACK 或程序捕获异常
- redo/undo 作用对象混淆 → 已提交 redo、未提交 undo
- 忘记总金额校验 → 一致性是最终目的，原子性只是手段
