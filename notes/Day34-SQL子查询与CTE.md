# Day34 · SQL 进阶：子查询与 CTE（标量/列/表子查询 / IN vs EXISTS / WITH）

> 模块三 · SQL 进阶 Day3 | 配套脚本见 `scripts/day34/` 目录，虚拟机实测通过。
> 背景：复杂查询拆解能力是数据开发日常，IN/EXISTS 对比与 CTE 是面试高频。

---

## 1. 子查询三种类型

### 标量子查询（返回单个值）
```sql
SELECT order_no, amount
FROM orders
WHERE amount > (SELECT AVG(amount) FROM orders);
```

### 列子查询（返回一列值）
```sql
SELECT user_id FROM user_main
WHERE id IN (SELECT user_id FROM orders);
```

### 表子查询（返回临时表，必须起别名）
```sql
SELECT user_id, order_no, amount
FROM (
    SELECT user_id, order_no, amount,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
    FROM orders
) t            -- ⚠️ 派生表必须起别名，否则 ERROR 1248
WHERE t.rn <= 2;
```

## 2. IN vs EXISTS（面试高频）

场景：查"有订单的用户"

```sql
-- IN：先执行子查询，结果集存内存
SELECT user_id FROM user_main WHERE id IN (SELECT user_id FROM orders);

-- EXISTS：相关子查询，外层逐行判断
SELECT user_id FROM user_main u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
```

| | IN | EXISTS |
|--|----|--------|
| 子查询执行 | 先执行，结果集存内存 | 外层逐行，去子查询判断 |
| 是否相关 | 不相关 | 相关（引用外层字段） |
| 性能原则 | 子查询结果集小用 IN | 外层表小用 EXISTS |
| NULL 处理 | 结果含 NULL 时 IN 不匹配 | 无影响 |

> 记忆：**小表驱动大表**——子查询结果集小用 IN；外层表小用 EXISTS。

## 3. MySQL 8.0 优化器改写（实操验证）

EXPLAIN 对比两条查询，执行计划几乎相同：
- 都出现 `FirstMatch` + `Using join buffer (hash join)`
- 说明 MySQL 8.0 把 IN/EXISTS **自动改写为 semi join**，实际执行趋同

> 面试要点：理论差异要会背（IN 先查、EXISTS 逐行）；实践上 8.0 优化器自动改写，性能差异不大；老版本/复杂场景仍按小表驱动大表判断。

## 4. CTE 公用表表达式（WITH）

用 WITH 定义临时结果集，像表一样引用，查询分层、可读性好。

```sql
-- CTE 版 TopN
WITH ranked AS (
    SELECT user_id, order_no, amount,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
    FROM orders
)
SELECT user_id, order_no, amount FROM ranked WHERE rn <= 2;

-- 多 CTE 层层递进
WITH
user_orders AS (SELECT user_id, COUNT(*) AS cnt FROM orders GROUP BY user_id),
high_users  AS (SELECT user_id FROM user_orders WHERE cnt >= 2)
SELECT * FROM high_users;
```

> CTE 优点：可读性好、可复用、支持递归（WITH RECURSIVE 做树形/连续日期展开）。

---

## 今日面试考点清单
1. 子查询三种类型？→ 标量/列/表；返回单值/一列/临时表
2. 表子查询别名？→ 必须起别名，ERROR 1248
3. IN vs EXISTS？→ 先查结果集 vs 逐行相关判断；小表驱动大表
4. MySQL8.0 对 IN/EXISTS？→ 自动改写 semi join
5. CTE 是什么/优点？→ WITH 临时结果集；分层可读、可复用、可递归

## 踩坑记录（面试素材）
- 表子查询忘别名 → ERROR 1248
- 以为 IN/EXISTS 性能差异巨大 → 8.0 优化器自动改写趋同
- EXISTS 子查询忘关联外层字段 → 变成非相关，逻辑错误
- 子查询结果含 NULL 用 IN → 匹配不到，注意 NULL
- CTE 与子查询选型 → 复杂多层优先 CTE 提升可读性
