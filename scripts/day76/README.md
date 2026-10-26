# Day76 实操：双链对账步骤

# 1. 离线链路：查权威 GMV（MySQL 数仓，status=2 口径）
mysql -uroot -p123456
use dw_project;
SELECT * FROM ads_gmv_report;   # 例：2026-10-12 | 59.00 | 1
exit

# 2. 实时链路：跑 RealTimeGmv（Day75 工程，先 flink list 无旧作业）
cd ~/py_learn/flink_project/socket_word
flink run -c com.example.RealTimeGmv target/socket-word-1.0.jar
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out

# 生产者输入（模拟离线那天的订单，口径 status=2）：
kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic
# 2001,59,2
# 预期实时输出：实时GMV[...~...) 订单数=1 GMV=59.0

# 3. 对账脚本：
cd ~/py_learn/flink_project/
python3 reconcile_check.py
# 输入：实时 59.0，离线 59.0 → [通过] 对账一致
# 若实时 59.0 离线 118.0 → [告警]，优先排查实时链路（丢数据/窗口/过滤）

# 要点：
# - Lambda=双链路(实时快+离线准)，两套维护贵；Kappa=单链路(Kafka重放)，重算贵
# - 对账前提：口径统一（GMV=status=2），否则全是噪音
