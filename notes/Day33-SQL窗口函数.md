# Day33 · SQL 进阶：窗口函数（排名 / 累加 / LAG-LEAD / 分组TopN）

> 模块三 · SQL 进阶 Day2 | 配套脚本见 `scripts/day33/` 目录，虚拟机实测通过。
> 背景：窗口函数是数据分析/开发面试必考核心，分组TopN 是经典场景题。

---

## 1. 窗口函数概念 & 语法

在**不合并行**的情况下，对每行计算窗口范围内的统计值。

| | GROUP BY | 窗口函数 |
|--|----------|----------|
| 行数 | 每组合并成一行 | 行数不变，每行保留 |
| 结果 | 只有组统计值 | 明细 + 统计值并存 |

**语法**：
```sql
函数() OVER (
    PARTITION BY 分组字段   -- 类似GROUP BY，但不合并行
    ORDER BY 排序字段        -- 窗口内排序
)
```

## 2. 三个排名函数（并列处理差异，面试必背）

分数 90,90,80 为例：

| 函数 | 特点 | 结果 |
|------|------|------|
| ROW_NUMBER() | 顺序编号，并列也分先后 | 1,2,3 |
| RANK() | 并列同号，跳跃 | 1,1,3 |
| DENSE_RANK() | 并列同号，不跳跃 | 1,1,2 |

## 3. 分组TopN（面试经典题标准解法）

**需求**：每个用户金额最高的前2个订单
```sql
SELECT user_id, order_no, amount
FROM (
    SELECT user_id, order_no, amount,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
    FROM orders
) t
WHERE t.rn <= 2;
```
> 思路：子查询排号 → 外层 WHERE rn<=2。**子查询 + ROW_NUMBER + 外层过滤**。

## 4. 累加求和

```sql
-- 整组求和（无ORDER BY）：每行都是该组总和
SUM(amount) OVER (PARTITION BY user_id)

-- 逐行累加（有ORDER BY）
SUM(amount) OVER (PARTITION BY user_id ORDER BY create_time, order_id) AS running_total
```

> ⚠️【坑】累加时 ORDER BY 字段值重复 → 默认 RANGE 帧把相同排序值的行**合并成同一帧一起累加**（如 99/199/49 同时间戳 → 直接 347 而非逐行累加）。修正：ORDER BY 加唯一字段（order_id），或 ROWS BETWEEN 明确帧。

## 5. LAG / LEAD 前后行

```sql
LAG(字段, n)   -- 取前面第n行值
LEAD(字段, n)  -- 取后面第n行值
SELECT user_id, order_no, amount,
       LAG(amount, 1) OVER (PARTITION BY user_id ORDER BY create_time) AS prev_amount
FROM orders;
-- 每组第一行 prev_amount=NULL
```
> 应用：环比、同比、连续登录判断（今天与昨天对比）。

---

## 今日面试考点清单
1. 窗口函数 vs GROUP BY？→ 行数不变 vs 合并行
2. 三个排名函数区别？→ 并列分先后/同号跳跃/同号不跳
3. 分组TopN 解法？→ 子查询+ROW_NUMBER+外层过滤
4. SUM() OVER(ORDER BY) vs OVER()？→ 逐行累加 vs 整组和
5. LAG/LEAD？→ 前n行/后n行，环比同比连续登录
6. RANGE 帧重复值坑？→ 相同排序值合并累加，加唯一排序字段

## 踩坑记录（面试素材）
- 窗口函数 ORDER BY 与 GROUP BY 混淆 → 窗口不合并行
- 累加遇到相同时间戳跳变 → RANGE 帧合并，加唯一字段
- 分组TopN 忘了子查询包裹 → rn 不能直接在 WHERE 用（执行顺序）
- RANK 与 DENSE_RANK 混淆 → 跳号 vs 不跳号
- LAG 第一行 NULL 没预期 → 每组边界行为 NULL
