# Day80 mini 项目运行步骤（实时订单数仓四层链路）

# 0. 前置：Kafka 在跑；pom 已有 flink-connector-kafka + Table API 依赖；无旧作业

# 1. 放入 FlinkSqlDw.java 并打包提交
cp FlinkSqlDw.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/
cd ~/py_learn/flink_project/socket_word
mvn -q package
flink run -c com.example.FlinkSqlDw target/socket-word-1.0.jar
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out

# 2. 生产者发数据（user_id,amount,status）：
kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic
# 4001,599,2
# 4002,199,1      ← 未支付，DWD 过滤
# 4003,99,2
# 4004,300,2

# 3. 预期输出（+I 插入模式；199 不出现）：
# +I[..., 599.0, 1]
# +I[..., 99.0, 1]
# +I[..., 300.0, 1]

# 4. 对账衔接：ADS 实时 GMV 与 MySQL ads_gmv_report 比对（Day76 reconcile_check.py）

# 生产版差距（面试可说）：
# - 处理时间 → 事件时间 + Watermark + allowedLateness（Day71/78）
# - print sink → MySQL/Redis sink（事务保证 Exactly-Once）
# - VIEW 逻辑层 → DWD/DWS 落 Kafka 主题物理分层
# - 单机 standalone → YARN/K8s 自动资源（Day72 金句）
