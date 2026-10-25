# Day73 实操：Kafka 安装 + 生产消费 + 消费组验证

# 1. 安装 Kafka 3.7.1（华为云镜像，ZK 模式）
cd /opt
sudo wget https://mirrors.huaweicloud.com/apache/kafka/3.7.1/kafka_2.13-3.7.1.tgz
sudo tar -xzf kafka_2.13-3.7.1.tgz
sudo mv kafka_2.13-3.7.1 kafka
sudo chown -R vboxuser:vboxuser /opt/kafka
echo 'export KAFKA_HOME=/opt/kafka' >> ~/.bashrc
echo 'export PATH=$KAFKA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 2. 启动（注意：配置文件路径手动敲 + Tab 补全，避免复制污染）
# 终端1：Zookeeper
/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
# 终端2：Kafka broker（看到 "Kafka Server started" 即成功）
/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties

# 3. 建 topic + 验证（bootstrap-server 用 127.0.0.1 绕开主机名解析）
kafka-topics.sh --list --bootstrap-server 127.0.0.1:9092
kafka-topics.sh --create --bootstrap-server 127.0.0.1:9092 --topic order_topic --partitions 3 --replication-factor 1
kafka-topics.sh --list --bootstrap-server 127.0.0.1:9092

# 4. 生产消费验证
# 终端3（生产者）：输入 1001,2999 / 1002,99 / 1003,118
kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic
# 终端4（消费者，无 group 从头读全部）：
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic --from-beginning

# 5. 消费组分摊实验（核心教学点）
# 终端A：--group my_group（保持运行）
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic --group my_group
# 终端B：--group my_group（另开一个，同组）
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic --group my_group
# 生产者发 1006,199 / 1007,299 / 1008,399
# 观察：A、B 各收到一部分（3 分区 2 消费者分摊），同一条不重复

# 踩坑备忘：
# - 配置路径被复制成 shturl.cc 短链 → 手动敲文件名/Tab 补全
# - Timed out waiting for node assignment → 用 127.0.0.1:9092
# - --group 前必须有空格，否则 topic 名被拼错
