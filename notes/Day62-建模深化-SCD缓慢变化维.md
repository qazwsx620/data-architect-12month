# Day62 · 建模深化：SCD 缓慢变化维（拉链表实战）

> 模块五 · 大数据数仓进阶 Day7（加量版）| 配套脚本见 `scripts/day62/`。
> 真实环境：MySQL 8.0（dw_project）。本日完成 SCD2 拉链表全流程实操。

---

## 1. SCD 解决什么问题

维度属性会变（用户改名、商品变价），而事实表记录的是"当时"的维度。直接改维度表 → 历史事实跟着变 → 报表失真。

## 2. SCD 三种类型（面试必答）

| 类型 | 做法 | 特点 | 适用 |
|------|------|------|------|
| SCD1 | 直接覆盖旧值 | 不保留历史，最简单 | 属性错了、不关心历史 |
| SCD2 | 新增一行，带生效/失效时间 | 保留全部历史版本 | 用户改名、商品变价（最常用） |
| SCD3 | 加"原值/现值"两列 | 只保留上一次变化 | 只需要"上一个值" |

## 3. 拉链表表结构（SCD2）

```sql
CREATE TABLE dim_user_scd2 (
  user_id     INT,          -- 业务主键（不变）
  user_name   VARCHAR(50),
  start_date  DATE,         -- 生效日
  end_date    DATE,         -- 失效日（NULL = 当前生效版本）
  PRIMARY KEY (user_id, start_date)   -- 同一用户同一生效期唯一
);
```

## 4. 拉链表更新三步（面试必答）

业务里用户改名，不是 UPDATE 覆盖，而是：

```text
① 失效旧版本：UPDATE 旧行 end_date = 变更前一天
② 新增新版本：INSERT 新行（变更日起生效，end_date = NULL）
③ 新用户：直接 INSERT（无旧版本可失效）
```

```sql
-- 1001 于 10-15 改名"张三丰"
UPDATE dim_user_scd2 SET end_date = '2026-10-14'
WHERE user_id = 1001 AND end_date IS NULL;
INSERT INTO dim_user_scd2 VALUES (1001, '张三丰', '2026-10-15', NULL);
```

最终拉链表：
```
1001 张三   2026-10-10 ~ 2026-10-14   （已失效）
1001 张三丰 2026-10-15 ~ NULL         （当前生效）
1002 李四   2026-10-10 ~ NULL
1003 王五   2026-10-10 ~ NULL
1004 赵六   2026-10-18 ~ NULL
```

## 5. 时间点快照查询（背公式）

```sql
SELECT user_id, user_name
FROM dim_user_scd2
WHERE start_date <= '2026-10-12'                 -- 生效不能晚于查询日
  AND (end_date IS NULL OR end_date >= '2026-10-12');  -- 失效不能早于查询日（NULL 永远有效）
```
- 10-12 快照 → 张三（历史正确）
- 10-16 快照 → 张三丰（变化后正确）
- 当前生效版本 → `WHERE end_date IS NULL`

---

## 今日面试考点清单
1. SCD 解决什么？→ 维度变化不污染历史事实
2. 三类型区别？→ 覆盖 / 新增行带时间 / 原值现值列
3. 拉链表三步？→ 失效旧行 + 新增新行 + 新用户直插
4. 为什么不能覆盖？→ 历史报表失真
5. 时间点查询公式？→ start_date<=d AND (end_date IS NULL OR end_date>=d)

## 易混淆坑
- end_date 口径：失效日 = 变更前一天（闭区间）；NULL = 当前生效
- 直接 UPDATE 覆盖 = SCD1（丢历史）
- 查询条件必须同时管住 start 和 end 两个边界
- SCD3 只保留上一次变化，不是全历史
