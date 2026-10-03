# Day28 · MySQL MVCC 多版本并发控制（隐藏列 / undo版本链 / Read View / 快照读vs当前读）

> 阶段01 · 第2月 | 配套脚本见 `scripts/day28/` 目录，虚拟机实测通过。
> 背景：MVCC 是 InnoDB 高并发读的核心机制，也是隔离级别的底层实现，面试进阶必考。

---

## 1. MVCC 概念

**MVCC（Multi-Version Concurrency Control）**：同一行数据保存多个历史版本，读操作读取快照版本（不加锁），写操作加锁，实现**读写不冲突**。

> 面试一句话：MVCC 让"读不加锁、读写互不阻塞"，是 InnoDB 高并发读的核心。

## 2. 三个隐藏列（MVCC 基础）

| 隐藏列 | 作用 |
|--------|------|
| DB_TRX_ID | 最近一次修改该行的事务 ID |
| DB_ROLL_PTR | 回滚指针，指向该行上一个版本的 undo log |
| DB_ROW_ID | 隐藏主键，无主键时 InnoDB 用它生成聚簇索引 |

## 3. undo log 版本链

每次 UPDATE：
1. 把修改前的旧值写入 undo log
2. 行的 DB_ROLL_PTR 指向新写的 undo log
3. 多个版本通过指针串成版本链（最新 → 最旧）

**两个核心用途**：
1. 事务回滚（恢复修改前数据）
2. MVCC 快照读（沿版本链找可见版本）

## 4. Read View（读视图）

快照读时生成的"可见性快照"，记录当时活跃（未提交）事务 ID 列表。
关键值：`min_trx_id`（活跃最小ID）、`max_trx_id`（已分配最大ID+1）。

**可见性判断规则**（看行上的 DB_TRX_ID）：
1. `DB_TRX_ID < min_trx_id`：已提交修改 → 可见
2. `DB_TRX_ID >= max_trx_id`：未来事务修改 → 不可见
3. `min_trx_id <= DB_TRX_ID < max_trx_id`：
   - 在活跃列表（未提交）→ 不可见
   - 不在活跃列表（已提交）→ 可见
4. 不可见 → 沿版本链向前找上一个版本

**Read View 生成时机（隔离级别差异的本质）**：
- REPEATABLE READ：事务第一次 SELECT 生成，**固定复用** → 可重复读
- READ COMMITTED：每次 SELECT 重新生成 → 可能不可重复读

## 5. 快照读 vs 当前读

| | 快照读 | 当前读 |
|--|--------|--------|
| SQL | 普通 SELECT | SELECT ... FOR UPDATE / LOCK IN SHARE MODE / UPDATE / DELETE / INSERT |
| 机制 | 读 Read View 快照版本，不加锁 | 读最新已提交版本，加锁 |
| 是否阻塞写 | 不阻塞（读写并行） | 阻塞其他写 |

## 6. MVCC 完整工作流程（面试口述）

```
1. 事务执行快照读（普通 SELECT）
2. 生成 Read View（活跃事务列表）
3. 读目标行，看 DB_TRX_ID
4. 可见性规则判断：可见返回；不可见沿版本链向前找
5. 返回可见版本
```

## 7. 运维补充：查看运行中事务

```sql
SELECT trx_id, trx_state FROM information_schema.innodb_trx;
-- 排查锁等待、长事务常用
```

---

## 今日面试考点清单
1. MVCC 解决什么问题？→ 读写不冲突、读不加锁
2. 三个隐藏列？→ TRX_ID / ROLL_PTR / ROW_ID
3. 版本链保存什么？→ 修改前旧值；回滚 + 快照读
4. Read View 是什么？→ 活跃事务快照，判断可见性
5. RR 与 RC 的 Read View 时机？→ 固定复用 vs 每次新生成
6. 快照读与当前读区别？→ 历史版本不加锁 vs 最新数据加锁
7. 可见性规则核心？→ 事务ID与 min/max_trx_id 比较

## 踩坑记录（面试素材）
- 以为 MVCC 读历史版本是"旧数据" → 是符合可见性规则的正确版本
- 把 DB_ROW_ID 当业务字段 → 隐藏主键，无主键时才用
- 当前读忘了加锁 → FOR UPDATE/LOCK IN SHARE MODE 才加锁
- RR 与 RC 混淆 Read View 时机 → RR 固定、RC 每次
- 残留事务影响实验 → 收尾 COMMIT/ROLLBACK + innodb_trx 检查
