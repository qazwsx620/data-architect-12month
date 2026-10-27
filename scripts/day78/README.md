# Day78 实操：迟到数据实验步骤

# 1. 放入 LateDataWindow.java（注意：侧输出流 tag 类型 = 窗口输入 Tuple3）
cp LateDataWindow.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/
cd ~/py_learn/flink_project/socket_word
mvn -q package
flink run -c com.example.LateDataWindow target/socket-word-1.0.jar
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out

# 2. nc 输入（order_id,amount,事件时间ms），关键顺序：
nc -lk 9999
# 1,10000,10000
# 2,11000,11000
# 3,12000,12000
# 4,25000,25000      → Watermark=22000 → 触发：3 单 33000
# 5,14000,14000      → 重触发：4 单 47000（Watermark 22000 < 25000，窗口存活）
# 6,12000,12000      → 重触发：5 单 59000（未推高 Watermark）
# 7,12000,12000      → 重触发：6 单 71000
# 8,30000,30000      → Watermark=27000 ≥ 25000 → 清窗
# 9,13000,13000      → 迟到旁路: order=9（窗口已清除）

# 3. 核心机制（易混淆坑）：
#    allowedLateness 不是"墙钟等 N 秒"！
#    清窗条件：Watermark ≥ 窗口结束时间 + allowedLateness
#    → 要让窗口关闭，必须来一条大事件时间数据把 Watermark 推过去
