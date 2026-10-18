# Day56 · Hive 深度：表类型与分区（内部/外部表 + 分区 + 分桶）

> 模块五 · 大数据数仓进阶 Day1（加量版）| 配套脚本见 `scripts/day56/`。
> 环境说明：虚拟机无 Hadoop/Hive/Java，按 Day41 策略走"原理 + 通用 SQL/文件系统模拟"路线，不降级交付。

---

## 1. Hive 数据模型（架构核心）

```text
Hive 数据库(database)
  └── 表(table)              ← 逻辑结构
        └── 分区(partition)    ← 目录级，按列值切（如 dt）
              └── 分桶(bucket)  ← 文件级，按哈希切（hash%N）
                    └── 行(row)
```
**元数据（表结构）存 MySQL/Derby，数据存 HDFS 文件**——表结构在 MySQL、数据在 HDFS，是 Hive 核心架构。

## 2. 内部表 vs 外部表（面试必答）

| | 内部表（管理表） | 外部表 |
|--|----------------|--------|
| 建表 | `CREATE TABLE t(...)` | `CREATE EXTERNAL TABLE t(...) LOCATION '...'` |
| 谁管数据 | Hive 管理 | 外部系统管理 |
| DROP 表 | 元数据+数据全删 | 只删元数据，数据保留 |
| 适用 | 临时表/中间表 | 原始数据/共享数据 |

> 类比：内部表=租房退租连家具搬走；外部表=自有房，人走房在。
> ODS 层用外部表：原始数据不想被误删。

```sql
-- 内部表
CREATE TABLE t1 (id INT, name STRING);
DROP TABLE t1;   -- 删元数据 + 删 HDFS 数据文件
-- 外部表
CREATE EXTERNAL TABLE t2 (id INT, name STRING) LOCATION '/data/t2';
DROP TABLE t2;   -- 只删元数据，/data/t2 数据保留
```

### 实操①模拟：MySQL 视图 ≈ Hive 外部表
普通表 DROP 后数据全没（≈内部表）；视图 DROP 只删壳、基表数据还在（≈外部表）。

## 3. 分区表（目录级裁剪）

分区 = HDFS 目录组织：`dt=2026-10-10/` 目录放该天数据。查询 `WHERE dt='...'` 只扫对应目录，不扫全表。

| | 静态分区 | 动态分区 |
|--|---------|---------|
| 写法 | `PARTITION(dt='2026-10-11')` | `PARTITION(dt) SELECT ..., dt FROM ...` |
| 分区值 | SQL 写死 | SELECT 数据自动推导 |
| 适用 | 每天跑当天 | 回刷历史（一次写多天） |

> 动态分区需 `hive.exec.dynamic.partition=true`。

### 实操②模拟：Linux 目录结构 + MySQL LIST 分区裁剪
- `mkdir /tmp/order_ods/dt=2026-10-10` → 体会"分区=目录"
- MySQL `PARTITION BY LIST (status)` + `EXPLAIN`：查 status=2 时 partitions 列只显示 `p_paid` → 分区裁剪生效。

## 4. 分桶表（文件级哈希）

```sql
CREATE TABLE dwd_order_bucket (
  order_id BIGINT, user_id BIGINT, amount DECIMAL(10,2)
)
CLUSTERED BY (user_id) INTO 4 BUCKETS;   -- hash(user_id)%4
```

| | 分区 | 分桶 |
|--|------|------|
| 切分方式 | 按列值（dt） | 按哈希（hash%N） |
| 粒度 | 目录级 | 文件级 |
| 场景 | 按日期裁剪扫描 | 抽样（TABLESAMPLE）/ JOIN 优化（SMB） |

> 同键同桶：同一 user_id 哈希相同 → 永远落同一桶 → 两表同分桶键可直接桶内 JOIN，减少 shuffle。

### 实操③模拟：Python 哈希分桶
8 条订单按 user_id%4 分 4 桶，同一 user_id（如 1001）订单全部落桶1 → 验证"同键同桶"。

---

## 今日面试考点清单
1. Hive 元数据/数据分别存哪？→ MySQL(Derby)/HDFS
2. 内部表 vs 外部表 DROP？→ 全删 vs 只删元数据
3. ODS 为什么外部表？→ 保护原始数据
4. 分区 vs 分桶？→ 列值/目录级 vs 哈希/文件级；裁剪 vs 抽样JOIN
5. 静态 vs 动态分区？→ 当天跑当天 vs 回刷历史

## 易混淆坑
- 内部表 DROP 数据也没了——重要数据千万别用内部表
- 分区=目录（按列值），分桶=文件（按哈希），粒度不同
- 动态分区可以一次写多天，但需开开关
- 视图类比外部表只到"DROP 行为"，视图不能写数据——教学模拟注意边界
