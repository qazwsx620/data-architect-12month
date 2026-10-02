# Day25 · MySQL 索引失效场景 & 索引设计原则（函数/隐式转换/like/or/负向查询）

> 阶段01 · 第2月 | 配套脚本见 `scripts/day25/` 目录，虚拟机实测通过。
> 背景：索引失效是面试高频考点，本文逐场景 explain 实测验证 + 索引设计原则总结。

---

## 1. 索引失效场景

### 场景1：对索引列做函数/运算
```sql
-- 索引列套函数 → 失效，全表扫描
EXPLAIN SELECT * FROM user WHERE YEAR(create_time)=2026;
-- 正确：运算放常量侧
EXPLAIN SELECT * FROM user WHERE create_time>='2026-01-01' AND create_time<'2027-01-01';

EXPLAIN SELECT * FROM user WHERE age+1=21;  -- 失效 ALL
EXPLAIN SELECT * FROM user WHERE age=20;    -- 走索引
```
> 口诀：索引字段不要做运算、套函数。

### 场景2：隐式类型转换
```sql
-- phone char(11) 有索引；传数字触发隐式转换，索引失效
EXPLAIN SELECT * FROM user WHERE phone=13800138000;      -- 失效
EXPLAIN SELECT * FROM user WHERE phone='13800138000';    -- 走索引
```
> MySQL 会 CAST(索引列) 再比较，等价于对索引列套函数。

### 场景3：like 模糊查询
```sql
CREATE INDEX idx_user_username ON user(username);
EXPLAIN SELECT * FROM user WHERE username LIKE 'zhang%';   -- ✅ 前缀匹配 range
EXPLAIN SELECT * FROM user WHERE username LIKE '%zhang';   -- ❌ 前缀通配符失效
EXPLAIN SELECT * FROM user WHERE username LIKE '%zhang%';  -- ❌ 失效
```
> 业务必须全模糊搜索时，MySQL B+ 树解决不了，需 ES 等搜索引擎。

### 场景4：or 条件
```sql
-- 一侧无索引 → 整体全表扫描
EXPLAIN SELECT * FROM user WHERE username='zhangsan' OR age=20;
-- 两边都有索引也不一定走：小表时优化器判定全表扫描更便宜，直接弃用索引
-- 稳定优化：UNION ALL 拆分
SELECT * FROM user WHERE username='zhangsan'
UNION ALL
SELECT * FROM user WHERE age=22;
```

### 场景5：负向查询（大概率失效，非绝对）
```sql
EXPLAIN SELECT * FROM user WHERE username != 'zhangsan';
```
- `!= / <> / NOT IN / IS NOT NULL` 大概率失效，但不是绝对
- 是否走索引取决于：满足条件数据占全表比例；占比低走索引，占比高全表扫描

### 场景6：低区分度字段
gender 只有 0/1 两个值，选择性差 → 即使建索引，优化器大概率弃用。

## 2. 索引设计核心原则

1. 优先为 where / order by / group by 字段建索引
2. 联合索引：等值在前、范围在后；高选择性字段靠前
3. 尽量建覆盖索引，减少回表
4. 索引不是越多越好：占磁盘、增删改维护索引降低写入性能
5. 低区分度字段（性别、状态）不适合建索引

---

## 今日面试考点清单
1. 索引失效场景有哪些？→ 函数/运算、隐式转换、like 前缀通配、or 一侧无索引、负向查询、低选择性
2. like 哪种能走索引？→ 'xxx%' 前缀匹配；'%xxx'/'%xxx%' 失效
3. 字符串字段查询不加引号？→ 隐式类型转换，索引失效
4. or 两边都有索引一定走？→ 不一定，优化器评估全表更便宜就弃用
5. 负向查询一定失效？→ 不一定，看满足条件数据占比
6. 索引设计原则？→ 高频查询字段、联合索引顺序、覆盖索引、不过量、避开低区分度

## 踩坑记录（面试素材）
- 以为 or 两边有索引必走 → 小表全表扫描更便宜，用 union all 稳定
- 字符串字段不加引号 → 隐式转换索引失效
- like '%xxx' 以为可以走 → 前缀通配符失效
- 负向查询一刀切说失效 → 看数据占比，不是绝对
- 给性别这种低区分度字段建索引 → 优化器基本不用
