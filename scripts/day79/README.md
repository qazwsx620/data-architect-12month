# Day79 实操：Flink SQL 窗口聚合步骤

# 0. 前置：Kafka 在跑（jps）；无旧作业（flink list + cancel）

# 1. pom.xml 追加 Table API 依赖：
#    <dependency>
#        <groupId>org.apache.flink</groupId>
#        <artifactId>flink-table-api-java-bridge</artifactId>
#        <version>1.19.1</version>
#    </dependency>
#    <dependency>
#        <groupId>org.apache.flink</groupId>
#        <artifactId>flink-table-planner-loader</artifactId>
#        <version>1.19.1</version>
#    </dependency>

# 2. 放入 FlinkSqlGmv.java 并打包（jar 变大属正常，planner 进来了）
cp FlinkSqlGmv.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/
cd ~/py_learn/flink_project/socket_word
mvn -q package
flink run -c com.example.FlinkSqlGmv target/socket-word-1.0.jar
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out

# 3. 生产者发数据（user_id,amount,status），10 秒内输入：
kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic
# 3001,599,2
# 3002,199,1
# 3003,99,2

# 预期输出（print sink，+I=插入模式）：
# +I[2026-10-27T08:29:10, 2026-10-27T08:29:20, 599.0, 1]   ← 199 被 WHERE status=2 过滤

# 要点：
# - SQL 声明式"算什么" vs DataStream 命令式"怎么算"
# - 动态表 = 流上持续更新的表（+I/-U/+U/-D 可见性）
# - 一行 SQL 完成窗口聚合（DataStream 版要几十行）
