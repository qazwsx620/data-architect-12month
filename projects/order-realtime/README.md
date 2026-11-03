# 实时订单数仓项目（Real-time Order Data Warehouse）

> 模块六（Day68-84）完整项目：从 Kafka 实时订单流到秒级 GMV 报表的全链路，Flink SQL 四层实时数仓 + 双链对账，单机可运行、可讲解、可复述。
> 配套代码：`scripts/day75-81`（Flink Java / SQL + 对账脚本）；架构雏形见 `scripts/day80/project_arch.md`。

---

## 1. 架构图

```
实时订单流                       实时数仓四层（存储=Kafka/Flink状态，计算=Flink SQL）           最终去向
Kafka order_topic ─────┐
(3分区, 原始订单流)     │ KafkaSource   ods(原样) ──→ dwd(清洗status=2) ──→ dws(10s窗口聚合)
                      └──→ Flink 1.19 SQL                                   │
                                                                   ads_realtime_gmv ──→ MySQL(报表) ──→ 实时大屏
                                                                            │
                                                                    对账脚本 reconcile_check.py
                                                                    (实时 vs 离线 ads_gmv_report 差异告警)
```

## 2. 实时数仓四层清单

| 层 | 存储/计算 | 职责 |
|----|----------|------|
| ODS | Kafka order_topic（3 分区） | 原始订单流接入，原样保留可回溯 |
| DWD | Flink SQL 视图 | 清洗、过滤 status=2（已支付口径统一集中） |
| DWS | Flink SQL TUMBLE 10s 窗口 | 轻度汇总：订单数 COUNT、GMV SUM |
| ADS | MySQL ads_realtime_gmv（print sink 演示） | 实时 GMV 报表 / 大屏 |
| 对账 | Python reconcile_check.py | 实时 ADS vs 离线权威表差异告警 |

落地表：`dw_project.ads_realtime_gmv(window_start PK, window_end, gmv, cnt)`

## 3. 脚本清单（scripts/day75-84）

| 脚本 | 职责 |
|------|------|
| RealTimeGmv.java | DWD 过滤 status=2 + DWS 窗口聚合（Day75） |
| reconcile_check.py | 双链对账（实时 vs 离线 ads_gmv_report） |
| DimJoinDemo.java | 维表关联（缓存/异步IO/广播 + 兜底侧输出） |
| LateDataWindow.java | 迟到数据三层处理（allowedLateness + 侧输出） |
| FlinkSqlDw.java | 四层链路 Flink SQL（Day80 主程序） |
| FlinkSqlReport.java | ADS 落 MySQL JDBC sink（Day81 主程序） |

## 4. 运行方式（虚拟机）

```bash
# 1. 启动 Kafka（ZK 模式）+ 建 topic
cd /opt/kafka && bin/zookeeper-server-start.sh config/zookeeper.properties &
bin/kafka-server-start.sh config/server.properties &
kafka-topics.sh --create --bootstrap-server 127.0.0.1:9092 --topic order_topic --partitions 3 --replication-factor 1

# 2. 启动 Flink standalone（1 TM × 1 slot，同时只能跑 1 个流作业）
/opt/flink/bin/start-cluster.sh

# 3. 打包（shade 含 SPI 合并，修复 JDBC factory 找不到）
cd ~/py_learn/flink_project/socket_word && mvn clean package

# 4. 提交作业（先 flink list，有 RUNNING 先 flink cancel）
flink run -c com.example.FlinkSqlDw target/socket-word-1.0.jar        # 四层链路（print 演示）
flink run -c com.example.FlinkSqlReport target/socket-word-1.0.jar    # 落 MySQL 报表

# 5. 生产数据（user_id,amount,status[,事件时间ms]，GMV 只认 status=2）
kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic
> 1001,2999,2

# 6. 查看结果
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out   # print 输出
mysql -uroot -p123456 -e "USE dw_project; SELECT * FROM ads_realtime_gmv;" # 落库结果

# 7. 双链对账（实时 ADS vs 离线 ads_gmv_report）
cd ~/py_learn/flink_project && python3 reconcile_check.py
```

## 5. 口径与规则

- **GMV 永远 status=2**（1=未付 / 2=已付 / 3=取消）；实时与离线同一口径，避免两套数字
- **窗口**：事件时间 TUMBLE 10s；触发=Watermark ≥ 窗口结束；清窗=≥ 结束 + allowedLateness
- **容错**：Checkpoint(5s) + Kafka offset 纳入状态快照，故障续跑不丢不重
- **可靠性**：迟到数据 allowedLateness + 侧输出；双链对账抓差异告警

## 6. 与离线项目的区别

| 维度 | 离线 order-dw | 实时 order-realtime |
|------|--------------|---------------------|
| 时效 | T+1（crontab 02:00） | 秒/分钟级（持续流） |
| 存储 | MySQL / Hive 表 | Kafka topic + Flink 状态 |
| 计算 | 批量 SQL | 流式 Flink SQL |
| 口径 | 精确 | 窗口近似（需对账） |
| 容错 | 幂等重跑 | Checkpoint + offset |

## 7. 生产差距（面试加分认知）
- 处理时间窗口 → 生产用事件时间 + Watermark + allowedLateness
- print sink → 生产用 MySQL/Redis Sink + 两阶段提交事务
- 单机 standalone → 生产 YARN/K8s 自动资源管理（TM 自动拉起）
- VIEW 逻辑分层 → 生产 DWD/DWS 落 Kafka 主题物理分层 + 调度监控
