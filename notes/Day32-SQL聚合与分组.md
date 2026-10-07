# Day32 · SQL 进阶：聚合与分组（聚合函数 / GROUP BY / HAVING / GROUP_CONCAT）

> 模块三 · SQL 进阶 Day1 | 配套脚本见 `scripts/day32/` 目录，虚拟机实测通过。
> 背景：聚合统计是数据开发最基础能力，HAVING 与 WHERE 区别是面试高频。

---

## 1. 聚合函数

| 函数 | 作用 |
|------|------|
| COUNT() | 计数：COUNT(*) 统计行数；COUNT(字段) 统计非NULL数 |
| SUM() | 求和 |
| AVG() | 平均值 |
| MAX() / MIN() | 最大值 / 最小值 |

## 2. GROUP BY 分组

按字段分组，配合聚合函数统计每组数据。

```sql
SELECT user_id, COUNT(*) AS order_cnt, SUM(amount) AS total_amount
FROM orders
GROUP BY user_id;
-- 结果：10001→4单347元、10002→2单358元、10003→2单548元
```

> ⚠️ ONLY_FULL_GROUP_BY（MySQL5.7+默认开启）：SELECT 字段不在 GROUP BY、也不在聚合函数中会报错——每组内该字段可能有多个不同值，取哪个不确定。

## 3. WHERE vs HAVING（面试高频）

| | WHERE | HAVING |
|--|-------|--------|
| 时机 | 分组前过滤行 | 分组后过滤组 |
| 聚合函数 | ❌ 不能使用 | ✅ 可以使用 |
| 顺序 | WHERE → GROUP BY | GROUP BY → HAVING |

```sql
-- 正确：HAVING 过滤组
SELECT user_id, COUNT(*) AS cnt
FROM orders
GROUP BY user_id
HAVING cnt > 2;

-- 组合：WHERE 先滤行，再分组，HAVING 滤组
SELECT user_id, COUNT(*) AS cnt, SUM(amount) AS total
FROM orders
WHERE status = 1
GROUP BY user_id
HAVING cnt >= 2;
```

**SQL 执行顺序（面试必背）**：
`FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY`

## 4. GROUP_CONCAT 拼接

把分组内某字段拼成字符串（默认逗号分隔）：
```sql
SELECT user_id, GROUP_CONCAT(order_no) AS order_list
FROM orders
GROUP BY user_id;
-- 自定义分隔符
SELECT user_id, GROUP_CONCAT(order_no SEPARATOR '|') AS order_list
FROM orders
GROUP BY user_id;
```

## 5. 多字段分组

```sql
SELECT user_id, status, COUNT(*) AS cnt, SUM(amount) AS total
FROM orders
GROUP BY user_id, status;
-- 按 (user_id, status) 组合分组，分组更细
```

---

## 今日面试考点清单
1. 聚合函数？→ COUNT/SUM/AVG/MAX/MIN
2. COUNT(*) vs COUNT(字段)？→ 行数 vs 非NULL数
3. WHERE vs HAVING？→ 前滤行后滤组；HAVING 可用聚合函数
4. SQL 执行顺序？→ FROM→WHERE→GROUP BY→HAVING→SELECT→ORDER BY
5. GROUP_CONCAT？→ 拼接，SEPARATOR 自定义分隔符
6. ONLY_FULL_GROUP_BY？→ SELECT 字段必须在 GROUP BY 或聚合函数内

## 踩坑记录（面试素材）
- WHERE 里写聚合函数报错 → HAVING 才能过滤组
- SELECT 字段不在 GROUP BY 报错 → ONLY_FULL_GROUP_BY，值不确定
- COUNT(字段) 以为统计行数 → 只统计非NULL
- GROUP_CONCAT 分隔符记反 → 默认逗号，SEPARATOR 自定义
- 执行顺序记成 SELECT 最前 → FROM 最先执行
