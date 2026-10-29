# Day81 实操：实时 GMV 落 MySQL + 双链对账

## 0. 前置
- Kafka 在跑；无旧作业（flink list；有 RUNNING 先 flink cancel <id>）
- MySQL：mysql -uroot -p123456

## 1. 建实时 ADS 表
```sql
USE dw_project;
CREATE TABLE IF NOT EXISTS ads_realtime_gmv (
  window_start TIMESTAMP(3) NOT NULL,
  window_end   TIMESTAMP(3),
  gmv DOUBLE,
  cnt BIGINT,
  PRIMARY KEY (window_start)
);
```

## 2. pom.xml 追加依赖（scope 默认 compile，必须打进 uber jar）
```xml
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-connector-jdbc</artifactId>
    <version>3.2.0-1.19</version>
</dependency>
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
    <version>8.0.33</version>
</dependency>
```

## 3. shade 插件必须加 SPI 合并（坑①修复）
```xml
<configuration>
  <transformers>
    <transformer implementation="org.apache.maven.plugins.shade.resource.ServicesResourceTransformer"/>
  </transformers>
</configuration>
```

## 4. 打包提交
```bash
cp FlinkSqlReport.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/
cd ~/py_learn/flink_project/socket_word
mvn -q package
# 验证 SPI 含 jdbc 工厂：
unzip -p target/socket-word-1.0.jar META-INF/services/org.apache.flink.table.factories.Factory | grep -i jdbc
flink run -c com.example.FlinkSqlReport target/socket-word-1.0.jar
```

## 5. 发数据（user_id,amount,status）
```bash
kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic
# 5001,599,2
# 5002,199,1      ← 未支付，过滤
# 5003,99,2
```

## 6. 等 15 秒（窗口关闭）后查表 + 对账
```sql
USE dw_project;
SELECT window_start, gmv, cnt FROM ads_realtime_gmv;          -- 实时
SELECT SUM(gmv) AS rt_gmv, SUM(cnt) AS rt_cnt FROM ads_realtime_gmv;
SELECT stat_date, gmv, order_cnt FROM ads_gmv_report;         -- 离线权威（status=2 口径）
```

## 踩坑速查
| 报错 | 根因 | 修复 |
|------|------|------|
| Could not find factory 'jdbc' | shade 覆盖 SPI 文件 | 加 ServicesResourceTransformer |
| Unknown column 'ws' | Flink 字段名 ≠ MySQL 列名 | 命名对齐 window_start/end |
| 作业 RESTARTING 循环 | sink 初始化/写入 SQL 失败 | 看 JM .log 的 Caused by |
| 表空 | 窗口未关闭；作业 FAILED；表没建 | flink list + 等 15s + DESC 表 |

## 面试点
- 选型：汇总 MySQL/Redis，明细 HBase/ES，大屏 Redis
- 延迟：窗口粒度 + 落库写入策略
- 对账前提：口径统一（status=2）
