# Day31 · MySQL 慢 SQL 优化 + 月末自测（慢查询日志 / 优化思路 / 模块收官）

> 阶段01 · 第2月收官 | 配套脚本见 `scripts/day31/` 目录，虚拟机实测通过。
> 背景：慢 SQL 优化是数据开发岗位日常与面试高频，本文为 MySQL 模块最后一课。

---

## 1. 慢查询日志（定位慢 SQL 入口）

| 参数 | 作用 |
|------|------|
| slow_query_log | 是否开启慢查询日志（ON/OFF） |
| long_query_time | 阈值秒数，超过才记录（默认10秒） |
| slow_query_log_file | 日志文件路径 |

```sql
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'long_query_time';
SHOW VARIABLES LIKE 'slow_query_log_file';
-- 临时开启 + 调低阈值（生产勿调0）
SET GLOBAL slow_query_log = ON;
SET GLOBAL long_query_time = 0;   -- 0 = 记录所有SQL，日志爆满，仅演示
```
```bash
sudo grep -B 5 "sleep" /var/lib/mysql/Ubuntu-data-dev-slow.log
```
> ⚠️ long_query_time=0 会记录每条 SQL，日志爆满；生产设 1~2 秒。

### 慢日志字段解读
```
# Query_time: 3.000868   -- 执行总耗时（核心）
# Lock_time: 0.000000    -- 锁等待时间
# Rows_sent: 1           -- 返回行数
# Rows_examined: 1       -- 扫描行数
```
> 面试：Rows_examined 远大于 Rows_sent = 扫描大量行只返回几条 = 没走索引，危险信号。

## 2. 慢 SQL 优化完整思路（面试核心大题）

### 第1步：explain 看执行计划
重点：`type`（是否ALL）、`key`（是否用索引）、`rows`（扫描行数）、`Extra`（filesort/temporary）。

### 第2步：对症优化

| 问题 | 优化 |
|------|------|
| type=ALL 全表扫描 | where 条件字段建索引 |
| 索引失效 | 函数放常量侧、字符串加引号、避免前缀通配 |
| 最左匹配断裂 | 调整字段顺序或重建联合索引 |
| Using filesort | order by 字段建索引 / 覆盖索引 |
| Using temporary | group by/distinct 字段建索引 |
| 回表过多 | 建覆盖索引 |

### 第3步：SQL 改写技巧
1. 避免 SELECT *，只查需要的字段
2. 深分页优化（延迟关联）：
```sql
-- 慢：LIMIT 深偏移
SELECT * FROM orders ORDER BY id LIMIT 100000,10;
-- 快：先子查询定位起点
SELECT * FROM orders
WHERE id >= (SELECT id FROM orders ORDER BY id LIMIT 100000,1)
ORDER BY id LIMIT 10;
```
3. 批量 INSERT 代替循环单条
4. 索引列不做运算/函数

### 第4步：索引设计复查
- 联合索引顺序（等值在前、范围在后、高选择性在前）
- 移除无用/重复索引

> 面试一句话：开启慢查询日志定位 → explain 看执行计划 → 建索引/改写SQL → explain 复查验证。

## 3. 月末综合自测（10题，全部答对通过）

1. 逻辑架构四层：连接层→服务层→引擎层→存储层 ✅
2. CHAR定长/VARCHAR变长；**VARCHAR(n) 的 n 是字符数不是字节数** ⚠️（易错）
3. 聚簇索引叶子存整行；回表=二级索引拿主键再查聚簇索引；覆盖索引避免回表 ✅
4. 最左匹配；`where a=1 and b>2 and c=3` → a、b 走索引，c 失效 ✅
5. 索引失效：函数套索引列、隐式类型转换、like 前缀通配、or 一侧无索引、负向查询 ✅
6. ACID：原子性(undo)、一致性(目标)、隔离性(锁+MVCC)、持久性(redo) ✅
7. 默认 REPEATABLE READ；解决脏读+不可重复读；MVCC快照+间隙锁基本解决幻读 ✅
8. 快照读历史版本不加锁；当前读最新加锁；RR固定Read View、RC每次重生成 ✅
9. 临键锁=记录锁+间隙锁；死锁自动回滚牺牲者 ✅
10. 主从复制三线程（dump/IO/SQL）；分库分表问题：跨库查询/分布式事务/全局ID/扩容 ✅

---

## 今日面试考点清单
1. 慢查询日志参数？→ slow_query_log / long_query_time / 日志文件
2. 慢日志字段？→ Query_time / Lock_time / Rows_sent / Rows_examined
3. 慢SQL优化流程？→ 定位 → explain → 建索引/改写 → 复查
4. 深分页怎么优化？→ 延迟关联（先子查询定位起点）
5. Rows_examined 大说明什么？→ 扫描多没走索引

## 踩坑记录（面试素材）
- long_query_time=0 → 所有SQL都记录，日志爆满
- grep 慢日志用 -A 看不到耗时 → 耗时在匹配行前，用 -B
- VARCHAR(n) n 当字节数 → 是字符数
- 深分页 LIMIT 偏移大 → 延迟关联优化
- 只优化 filesort 忘了 ALL → type=ALL 也要建索引
