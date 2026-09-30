# Day23 · MySQL explain 执行计划（type / key / rows / Extra 逐列解读）

> 阶段01 · 第2月 | 配套脚本见 `scripts/day23/` 目录，虚拟机实测通过。
> 背景：慢 SQL 优化核心工具；面试必考 type 顺序与 Extra 坏信号识别。

---

## 1. explain 是什么

```sql
EXPLAIN SELECT ...;
```
MySQL 优化器展示 SQL 的执行计划：走没走索引、扫多少行、怎么排序，是慢 SQL 优化的第一步。

## 2. 核心字段（6 个）

| 字段 | 含义 |
|------|------|
| id | 查询序号，执行顺序 |
| select_type | 查询类型（SIMPLE 简单 / 子查询 / UNION） |
| type | **最重要**：索引访问类型，性能从优到劣 |
| key | **实际使用的索引**；NULL = 没走索引 |
| rows | 预估扫描行数，越小越好 |
| Extra | 额外信息，识别好/坏信号 |

**type 性能顺序（面试必背）**：
`system > const > eq_ref > ref > range > index > ALL`
- ALL：全表扫描，最差，需要优化
- index：全索引扫描
- range：范围查询走索引（> < between in）
- ref：等值匹配走索引（普通索引）
- const/system：主键/唯一索引等值查询，只扫一行，最好

## 3. 实操对比（实测结果）

### 等值查询 ref
```sql
EXPLAIN SELECT * FROM idx_demo WHERE name='zhangsan';
-- type=ref, key=idx_name, rows=1 → 普通索引等值匹配，好
```

### 无索引条件 ALL
```sql
EXPLAIN SELECT * FROM idx_demo WHERE age>20;
-- type=ALL, key=NULL, Extra: Using where → 全表扫描
-- 联合索引(name,age)最左列缺失，索引失效；建单列索引 idx_age 后变 range
```

### 范围查询 range（建索引后）
```sql
CREATE INDEX idx_age ON idx_demo(age);
EXPLAIN SELECT * FROM idx_demo WHERE age>20;
-- type=range, key=idx_age, Extra: Using index condition（ICP 索引下推）
```

### 文件排序 filesort
```sql
EXPLAIN SELECT * FROM idx_demo ORDER BY age;
-- Extra: Using filesort → order by 字段无可用索引，额外排序
EXPLAIN SELECT age FROM idx_demo ORDER BY age;
-- 覆盖索引后可消除 filesort
```

### group by 临时表
```sql
EXPLAIN SELECT age,count(*) FROM idx_demo GROUP BY age;
-- 有 idx_age 时：Using index，无临时表；无索引时会出现 Using temporary
```

## 4. Extra 信号识别（面试重点）

**好信号**：
- `Using index`：覆盖索引，不回表
- `Using index condition`：ICP 索引下推，存储引擎层过滤，减少回表

**坏信号**：
- `Using filesort`：无法用索引排序，额外文件/内存排序 → 给 order by 字段加索引
- `Using temporary`：需要临时表（group by/distinct 无索引、多表 join 分组）→ 加索引
- `ALL`：全表扫描 → 检查 where 条件能否走索引

**中性**：
- `Using where`：存储引擎返回后服务层过滤，不等于索引失效

## 5. possible_keys vs key

- `possible_keys`：优化器评估**候选可用索引**
- `key`：最终**实际选用**的索引
- 候选有但 key=NULL：优化器评估走索引开销 > 全表扫描，放弃索引（数据量小/回表多时常见）

---

## 今日面试考点清单
1. type 性能从优到劣？→ system>const>eq_ref>ref>range>index>ALL
2. ALL 怎么优化？→ where 条件建索引、避免最左列缺失、避免函数/隐式转换
3. Using index 含义？→ 覆盖索引不回表
4. Using filesort 原因？→ order by 无索引 / 不满足最左匹配
5. Using temporary 场景？→ group by/distinct 无索引、多表 join 分组
6. possible_keys 与 key 区别？→ 候选 vs 实际选用；key=NULL 优化器弃用索引
7. Using where 是否索引失效？→ 不是，只是服务层过滤
8. ICP 是什么？→ Using index condition 索引下推，减少回表

## 踩坑记录（面试素材）
- 把 Using where 当索引失效 → 只是服务层过滤，看 key 列判断
- 只看 type 不看 key → possible_keys 有索引但 key 为 null，说明被弃用
- 联合索引单查后列 age → 全表扫描 ALL，需单列索引或最左列
- select * 排序产生 filesort → 覆盖索引查询可消除
- 以为 filesort 一定在磁盘 → 内存不够才落盘
