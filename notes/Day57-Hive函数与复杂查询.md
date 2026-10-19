# Day57 · Hive 函数与复杂查询（内建函数 + 窗口函数 + UDTF）

> 模块五 · 大数据数仓进阶 Day2（加量版）| 配套脚本见 `scripts/day57/`。
> 环境说明：虚拟机无 Hive，按既定策略走"原理 + MySQL 模拟 + Hive 语法对照"（Hive 与 MySQL 8 函数语法几乎一致）。

---

## 1. Hive 常用内建函数（四类）

| 类别 | Hive 函数 | 作用 |
|------|-----------|------|
| 字符串 | concat / substr / upper / length / replace | 拼接、截取、大小写、长度、替换 |
| 日期 | date_format / datediff / date_add | 格式化、天数差、加天 |
| 条件 | if / case when / coalesce / nvl | 分支判断、空值兜底 |
| 类型转换 | cast(x as int/double/string) | 类型强制转换 |

> 面试点：Hive 与 MySQL 函数大体同名（concat/substr/datediff/if/coalesce/cast 都一样）；差异：Hive 空值函数 `nvl`，MySQL 是 `ifnull`。

### 实操①：订单数据四类函数（MySQL 模拟）
```sql
SELECT order_id,
       CONCAT('ORD-', order_id)              AS order_code,
       DATE_FORMAT(order_date, '%Y-%m')      AS month_part,
       DATEDIFF('2026-10-19', order_date)    AS days_ago,
       IF(status_name = '已支付', 'PAID', 'NOT_PAID') AS paid_flag,
       COALESCE(amount, 0)                   AS amount_filled,
       CAST(amount AS SIGNED)                AS amount_int
FROM dwd_order_detail;
```

## 2. 窗口函数在 Hive（与 MySQL 8 一致）

`row_number()/rank()/dense_rank()`、`sum() over(partition by ... order by ...)`——Hive/MySQL/Spark SQL 通用，面试可直接说"窗口函数跨引擎通用"。

- TopN：`ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC)` + 外层 `WHERE rn<=2`
- 累加：`SUM(amount) OVER (ORDER BY order_date, order_id)` —— 无 partition by 时，**全局累计到当前行**（从第一行到当前行）。

## 3. UDTF：explode + lateral view（行转列）

场景：一行存多个值（如标签数组），分析时要一行展开多行。

```sql
-- explode：数组/Map 拆多行（只能输出拆出的列）
SELECT explode(array('秒杀','会员','新品'));

-- lateral view：explode 与主表字段联合（关键）
SELECT order_id, tag
FROM orders
LATERAL VIEW explode(tags) t AS tag;
```

> 面试点：**explode 单独用只能输出数组列；要带出主表其他字段（order_id），必须用 LATERAL VIEW 关联**。

### 实操③模拟（MySQL 无 explode，用序列表拆逗号串）
```sql
WITH seq AS (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
             UNION ALL SELECT 4 UNION ALL SELECT 5)
SELECT o.order_id,
       SUBSTRING_INDEX(SUBSTRING_INDEX(o.tags, ',', s.n), ',', -1) AS tag
FROM order_tags o
JOIN seq s ON s.n <= (LENGTH(o.tags) - LENGTH(REPLACE(o.tags, ',', '')) + 1)
ORDER BY o.order_id, tag;
```
结果：30001→会员/秒杀、30002→新品、30003→会员/新品/秒杀（6 行）。

---

## 今日面试考点清单
1. 四类内建函数？→ 字符串/日期/条件/转换各举2例
2. Hive vs MySQL 空值函数？→ nvl vs ifnull
3. 窗口函数跨引擎通用？→ Hive/MySQL/Spark SQL 语法一致
4. 无 partition by 的 SUM OVER？→ 全局累计到当前行
5. explode 与 lateral view？→ 单独只输出数组列，配合才带主表字段

## 易混淆坑
- nvl 是 Hive，ifnull 是 MySQL（别混）
- explode 单独用丢主表字段，必须 lateral view
- 无 partition by 的累计 = 全局到当前行，不是全表合计
- Hive 的 substr 与 MySQL 的 SUBSTRING 是同功能不同名（Hive 更简）
