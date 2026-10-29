# Day81 · 实时报表 + 双链验证（ADS 落 MySQL + 对账）

> 模块六 · 实时数仓实战 Day14 | 配套脚本见 `scripts/day81/`（FlinkSqlReport.java + README）。
> 真实环境：Flink 1.19 SQL + Kafka 3.7.1 + MySQL 8，实时 GMV 落 `ads_realtime_gmv` 表跑通。

---

## 1. ADS 落库选型（面试必答）

| 存储 | 适合什么 | 特点 |
|------|----------|------|
| **MySQL** | 汇总指标（GMV/订单数）、报表展示 | 结构化、点查、可 JOIN；写频低（窗口结果才写） |
| **Redis** | 大屏实时刷新、高频点查 KV | 亚毫秒；配 TTL |
| **ES** | 多维检索、明细日志查询 | 倒排索引、聚合查询 |
| **HBase** | 海量明细、低延迟随机读 | 宽表、按 rowkey 查 |

> 选型原则：汇总指标 → MySQL/Redis；明细数据 → HBase/ES；大屏 → Redis。

## 2. 实时报表链路
```text
Kafka → Flink 窗口聚合 → ADS 落 MySQL/Redis → 报表层（Web/BI）读库展示
print 仅教学演示；生产 ADS 必须落可查询存储。
```

## 3. 延迟控制（面试必答）

直接两环节：
```text
① 窗口粒度：10s/1min 窗口决定结果更新频率
② 落库写入策略：攒批 + 事务提交（不逐条写库）
```
保障层：并行度 + 背压治理（Day84）、异步 IO 维表查询（Day77）、只写窗口结果。

## 4. ADS 为什么只写聚合结果，不写每条明细
```text
① 写入压力：逐条写 = 高频小事务，连接/IO/锁压力大；窗口结果每分钟几条、攒批写
② 表用途：ADS 服务报表/大屏，只要 GMV/订单数；明细归 DWD（Kafka/HBase）
③ 成本与查询：汇总表行数小、点查快、存储省
```

## 5. 实操：FlinkSqlReport.java（四层 + JDBC sink）

```java
// ODS：Kafka order_tb
// DWD：CREATE VIEW dwd_order AS ... WHERE status = 2
// DWS：CREATE VIEW dws_gmv AS TUMBLE 10s 窗口，别名 window_start/window_end/gmv/cnt
// ADS：CREATE TABLE ads_mysql WITH ('connector'='jdbc', table-name='ads_realtime_gmv',
//      buffer-flush.max-rows=1, interval=1s)
// INSERT INTO ads_mysql SELECT * FROM dws_gmv
```

MySQL 表：
```sql
CREATE TABLE ads_realtime_gmv (
  window_start TIMESTAMP(3) NOT NULL,
  window_end   TIMESTAMP(3),
  gmv DOUBLE,
  cnt BIGINT,
  PRIMARY KEY (window_start)
);
```

实测结果（5001,599,2 / 5002,199,1 / 5003,99,2）：
```text
| window_start             | gmv | cnt |
| 2026-10-29 20:06:10.000  | 599 | 1   |
| 2026-10-29 20:06:20.000  | 99  | 1   |
# 199 未支付被 DWD 过滤
```

## 6. 本次踩坑 2 连（重点排错记录）

### 坑①：Could not find factory 'jdbc'（SPI 被 shade 覆盖）
- 现象：可用工厂只有 blackhole/datagen/filesystem/kafka/print/upsert-kafka
- 根因：多个 connector 的 `META-INF/services/org.apache.flink.table.factories.Factory` 是 SPI 文件，maven-shade-plugin 默认不合并，互相覆盖后 jdbc 工厂注册信息丢失
- 验证：`unzip -p target/xxx.jar META-INF/services/org.apache.flink.table.factories.Factory`
- 修复：shade 插件加 ServicesResourceTransformer：
```xml
<transformers>
  <transformer implementation="org.apache.maven.plugins.shade.resource.ServicesResourceTransformer"/>
</transformers>
```

### 坑②：Unknown column 'ws' in 'field list'（命名不对齐）
- 根因：JDBC sink 按 Flink 表字段名拼 INSERT SQL（无列名映射选项），Flink 侧 ws/we 与 MySQL 物理列 window_start/window_end 不符
- 修复：Flink schema 字段名与物理表列名一一对应；类型也要对齐（TIMESTAMP(3)/DOUBLE/BIGINT）
- 补充：主键（PRIMARY KEY ... NOT ENFORCED）决定 upsert 语义，同窗口重复输出覆盖更新

## 7. 双链对账
```text
实时 ads_realtime_gmv（秒级窗口） vs 离线 ads_gmv_report（T+1）
前提：口径统一（都只算 status=2）
常态差异：窗口近似、数据延迟、迟到数据、口径偏差 → 差异超阈值告警
生产：离线 T+1 补数后按日期字段对齐两表 GMV（Day76 reconcile_check.py 思路）
```

---

## 今日面试考点清单
1. ADS 选型？→ 汇总 MySQL/Redis，明细 HBase/ES，大屏 Redis
2. 延迟两环节？→ 窗口粒度 + 落库写入策略
3. JDBC 对齐？→ 字段名 + 类型；主键定 upsert
4. 为什么只写聚合？→ 写入压力 + 表用途 + 成本
5. 对账前提？→ 口径统一

## 易混淆坑
- SPI 工厂找不到 ≠ 依赖没加（类在 jar 里但注册信息被覆盖）
- Flink JDBC 不支持列名映射，命名必须物理对齐
- 处理时间窗口要等窗口关闭才有结果，发完数据立刻查表为空
- 实时新数据离线表没有对应记录，demo 阶段先验证落库链路与口径，不强行比数值
