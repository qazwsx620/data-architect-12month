# Day74 实操：Kafka + Flink 管道运行步骤

# 0. 前置：Kafka broker 必须已在运行（jps 有 QuorumPeerMain + Kafka）
#    没有就手动起：
#    /opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
#    /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties

# 1. pom.xml 追加依赖（注意独立版本号！Flink 1.19 对应 3.2.0-1.19）：
#    <dependency>
#        <groupId>org.apache.flink</groupId>
#        <artifactId>flink-connector-kafka</artifactId>
#        <version>3.2.0-1.19</version>
#    </dependency>

# 2. 放入 KafkaOrderAgg.java 并打包（首次下载依赖稍等）
cp KafkaOrderAgg.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/
cd ~/py_learn/flink_project/socket_word
mvn -q package

# 3. 提交（先确认无旧作业占 slot）
flink list
flink run -c com.example.KafkaOrderAgg target/socket-word-1.0.jar

# 4. 跟踪输出（另一终端）：
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out

# 5. 生产者发数据（另一终端），10 秒内输入几条：
kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic
# 2001,599
# 2002,199
# 2003,99

# 预期输出：Kafka窗口[...~...) 订单数=N 金额=X（处理时间 10s 窗口）

# 要点：
# - KafkaSource 并行度上限 = topic 分区数（本 topic 3 分区）
# - 开 Checkpoint 后 offset 以状态存快照，恢复续读（不丢不重）
# - connector 版本独立于 Flink 主版本（1.17 起）
