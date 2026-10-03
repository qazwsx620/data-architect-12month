# Day27 · MySQL 事务隔离级别（脏读/不可重复读/幻读 / 四级别 / MVCC快照）

> 阶段01 · 第2月 | 配套脚本见 `scripts/day27/` 目录，虚拟机双会话实测通过。
> 背景：并发事务隔离是面试重灾区，四种隔离级别与读异常一一对应关系必背。

---

## 1. 三种读异常（并发事务不隔离的后果）

1. **脏读 Dirty Read**：读到其他事务**未提交**的修改；对方回滚则数据不存在
2. **不可重复读 Non-Repeatable Read**：同一事务内两次读**同一行**，结果不一致（被其他已提交事务修改）
3. **幻读 Phantom Read**：同一事务内两次查**同一范围**，行数变化（插入/删除）

| 问题 | 关注点 | 典型场景 |
|------|--------|----------|
| 脏读 | 读到未提交数据 | A未提交，B读到 |
| 不可重复读 | 同一行两次读不一致 | 一行被其他事务修改并提交 |
| 幻读 | 同一范围行数变化 | 插入/删除新行 |

## 2. 四种隔离级别（面试必背）

| 隔离级别 | 脏读 | 不可重复读 | 幻读 |
|----------|------|------------|------|
| READ UNCOMMITTED | 可能 | 可能 | 可能 |
| READ COMMITTED | 解决 | 可能 | 可能 |
| REPEATABLE READ | 解决 | 解决 | InnoDB 基本解决（MVCC+间隙锁） |
| SERIALIZABLE | 解决 | 解决 | 解决 |

> 从左到右隔离增强、**并发性能降低**。
> **MySQL InnoDB 默认：REPEATABLE READ**（高频考点）。

```sql
-- 查看
SELECT @@transaction_isolation;
-- 设置（当前会话）
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

## 3. 实操：双会话复现（实测结果）

### 脏读（会话B 改 READ UNCOMMITTED）
```
A: BEGIN; UPDATE account SET balance=500 WHERE name='张三';   -- 未提交
B(READ UNCOMMITTED): 查询 → 读到 500（脏读）
B(REPEATABLE READ):  查询 → 读到 800（隔离生效）
A: ROLLBACK
```

### 不可重复读（会话B 改 READ COMMITTED）
```
B(READ COMMITTED): BEGIN; 第一次读 300
A: UPDATE balance=200; COMMIT
B: 第二次读 200 → 不一致，不可重复读
```

### 可重复读（会话B REPEATABLE READ）
```
B(REPEATABLE READ): BEGIN; 第一次读 200
A: UPDATE balance=100; COMMIT
B: 第二次读 200 → 一致，可重复读（MVCC 快照）
```

## 4. MVCC 快照机制（理解层面）

- **READ COMMITTED**：每次 SELECT 生成新快照 → 读到最新已提交数据 → 可能不可重复读
- **REPEATABLE READ**：事务第一次 SELECT 生成快照，后续都基于同一快照 → 前后一致 → 不不可重复读
- 普通快照读靠 MVCC 防幻读；当前读（SELECT ... FOR UPDATE）靠**间隙锁**防幻读

---

## 今日面试考点清单
1. 三种读异常定义？→ 脏读未提交、不可重复读同行不一致、幻读范围行数变
2. MySQL 默认隔离级别？→ REPEATABLE READ
3. 四级别从低到高？→ RU < RC < RR < Serializable
4. RR 解决哪些问题？→ 脏读+不可重复读；MVCC+间隙锁基本解决幻读
5. RC 与 RR 差异？→ 每次读新快照 vs 固定快照
6. 快照读与当前读区别？→ MVCC 快照 vs 间隙锁

## 踩坑记录（面试素材）
- 以为 RR 完全解决幻读 → InnoDB 靠 MVCC+间隙锁"基本"解决，理论未完全消除
- 忘记默认隔离级别 → 面试高频，REPEATABLE READ
- RC/RR 快照机制混淆 → RC 每次新快照，RR 固定快照
- 实验顺序：脏读要先改 RU 才能复现；RR 下复现不了脏读
- 实验完忘记清理事务/改回级别 → 收尾 COMMIT + 恢复 REPEATABLE READ
