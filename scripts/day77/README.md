# Day77 实操：维表关联运行步骤

# 0. 前置：Kafka 在跑（jps 有 QuorumPeerMain + Kafka）；无则手动启动

# 1. 放入 DimJoinDemo.java 并打包
cp DimJoinDemo.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/
cd ~/py_learn/flink_project/socket_word
mvn -q package

# 2. 提交前确认无旧作业（flink list + cancel）
flink run -c com.example.DimJoinDemo target/socket-word-1.0.jar
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out

# 3. 生产者输入（含一个不在维表的用户 9）：
kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic
# 1,599,2
# 2,99,2
# 9,100,2

# 预期输出：
# 订单user=1(张三) 金额=599.0 status=2
# 订单user=2(李四) 金额=99.0 status=2
# 订单user=9(未知用户) 金额=100.0 status=2

# 要点：
# - 实时 Join 难点：维表不在流里，每条都查 → IO 瓶颈
# - 生产三件套：缓存 + 异步IO + 广播更新（内存 Map 只是教学简化）
# - 维表查不到：兜底"未知"保明细 + 生产用侧输出流暂存待补
