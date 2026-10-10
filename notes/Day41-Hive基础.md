# Day41 · Hive 基础（数仓查询入口：概念 / 架构 / 分区表 / 内外部表 / 工具生态）

> 模块三 · 数仓基础 Day2 | 配套脚本见 `scripts/day41/` 目录，环境受限以 HQL 语法练习为主。
> 背景：Hive 是离线数仓经典工具，Hive 与 MySQL 对比、分区表、内外部表是面试高频。

---

## 1. Hive 是什么（一句话给面试官）

**Hive = 把 SQL 翻译成分布式计算任务的"翻译官"**，架在 Hadoop 之上：
- 用类 SQL（HQL）写查询
- 翻译成 MapReduce/Tez/Spark 任务跑在集群
- 数据存在 HDFS（分布式文件系统）

**为什么不用 MySQL 处理大数据**：MySQL 单机存储/计算有限（GB级），Hive 数据在 HDFS（TB/PB级）+ 分布式并行计算。

## 2. Hive vs MySQL（核心对比）

| | MySQL | Hive |
|--|-------|------|
| 定位 | OLTP 联机事务 | OLAP 数仓分析 |
| 数据规模 | GB 级 | TB/PB 级 |
| 存储 | 本地磁盘 | HDFS 分布式 |
| 计算 | 自身执行 | 翻译成 MR/Spark |
| 延迟 | 毫秒级 | 秒~分钟级 |
| 场景 | 业务在线交易 | 离线批量分析 |

> 记忆：MySQL 管交易（快），Hive 管分析（大）。业务库存 MySQL，数仓分析用 Hive。

## 3. Hive 架构（三个关键组件）

```
用户写 HQL
   ↓
Hive 驱动（翻译 SQL → 执行计划）
   ├── MetaStore 元数据（表结构存 MySQL）
   └── 调度执行 → HDFS 存数据
```
- **MetaStore**：存表结构/分区等元数据（用 MySQL 存）
- **HDFS**：数据实际存储
- **执行引擎**：MapReduce / Tez / Spark（新版 Spark 多）

## 4. 分区表（数仓核心）

```sql
CREATE TABLE dwd_order_detail (
    order_id BIGINT, user_id BIGINT, amount DECIMAL(10,2), status TINYINT
)
PARTITIONED BY (dt STRING)          -- 按天分区
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';
```
**作用**：HDFS 数据 TB/PB 级，全表扫描代价大；分区后 WHERE dt='2026-10-09' **只扫当天分区（分区裁剪）**，扫描量从全量降到一天。

## 5. 内部表 vs 外部表

| | 内部表（管理表） | 外部表 |
|--|------------------|--------|
| 数据文件 | Hive 管理（数仓目录下） | 外部管理（HDFS 指定路径） |
| DROP 删表 | 元数据 + 数据一起删 | 只删元数据，数据保留 |

```sql
CREATE TABLE t_internal (id BIGINT);              -- 内部表
CREATE EXTERNAL TABLE t_external (id BIGINT)      -- 外部表
LOCATION '/data/ods/xxx';
```
> **ODS 原始数据用外部表**（数据是业务方的，删表不能删数据）；加工中间表用内部表。

## 6. 数仓工具生态演进（面试常问"你们用什么"）

| 工具 | 定位 |
|------|------|
| Hive | 离线批处理数仓（传统） |
| Spark SQL | 离线批处理更快（内存计算） |
| Doris / StarRocks | 实时数仓 + 报表查询（MPP） |
| Flink | 实时流处理 |

> 演进：Hive（慢）→ Spark SQL（快）→ Doris/StarRocks（实时），分层建模思想贯穿始终。

## 7. 实操：HQL 综合练习（纸面完成）

```sql
-- 外部表 + 分区表 + 指定路径
CREATE EXTERNAL TABLE ods_user_log(
    user_id BIGINT, action STRING
)
PARTITIONED BY (dt STRING)
LOCATION '/data/ods/user_log';

-- 每天每个用户每个动作的次数
SELECT dt, user_id, action, COUNT(*) AS cnt
FROM ods_user_log
GROUP BY dt, user_id, action;
```

---

## 今日面试考点清单
1. Hive 是什么？→ SQL 翻译成分布式任务的翻译官
2. Hive vs MySQL？→ OLAP/OLTP、TB/GB、HDFS/磁盘、MR/自身
3. 分区表作用？→ 分区裁剪只扫需要分区
4. 内外部表？→ 删表数据去留不同；ODS 用外部表
5. 工具生态演进？→ Hive→Spark SQL→Doris/StarRocks

## 踩坑记录（面试素材）
- 以为 Hive 是数据库 → 是数仓分析工具/翻译官
- 分区表不建 → 全表扫描 TB 级数据慢到爆
- ODS 用内部表 → 删表删业务数据，必须外部表
- Hive 当 OLTP 用 → 秒分钟延迟不适合在线
- 忘记元数据 MetaStore → 表结构存 MySQL 而非 HDFS
