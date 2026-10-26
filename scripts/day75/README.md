# Day75 实操：实时 GMV 管道运行步骤

# 0. 前置：Kafka 在跑（jps 有 QuorumPeerMain + Kafka）；无则手动启动

# 1. 放入 RealTimeGmv.java 并打包
cp RealTimeGmv.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/
cd ~/py_learn/flink_project/socket_word
mvn -q package

# 2. 提交前先看有无旧作业（1 slot 只能跑 1 个），有则 cancel
flink list
# flink cancel <旧作业JobID>   ← 关键！旧 KafkaOrderAgg 不读 status，会污染结果

# 3. 提交 + 跟踪输出
flink run -c com.example.RealTimeGmv target/socket-word-1.0.jar
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out

# 4. 生产者发数据（格式 user_id,amount,status）：
kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic
# 2001,599,2
# 2002,199,1
# 2003,99,2

# 预期输出：实时GMV[...~...) 订单数=2 GMV=698.0（599+99；199 未支付被 status=2 过滤）

# 要点：
# - 实时四层：ODS(Kafka原始流) → DWD(过滤status=2) → DWS/ADS(10s窗口GMV)
# - 输出前缀区分作业：Kafka窗口=旧作业 / 实时GMV=本作业
# - GMV 口径 status=2，与离线一致（防止两套数字）
