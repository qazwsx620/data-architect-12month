# Day71 实操：EventTimeWindow 运行步骤

# 1. 放入工程：
#    cp EventTimeWindow.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/

# 2. 打包 + 提交（先 flink list 确认无旧作业占 slot）
cd ~/py_learn/flink_project/socket_word
mvn -q package
flink list   # 有 RUNNING 先 flink cancel <jobid>
flink run -c com.example.EventTimeWindow target/socket-word-1.0.jar

# 3. print 输出跟踪（另一终端）：
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out

# 4. nc 数据源，输入乱序数据（order_id,amount,事件时间毫秒）：
nc -lk 9999
# 1,2999,10000
# 2,99,11000
# 3,118,8000        ← 乱序：事件时间 8s 最后到
# 4,399,14000
# 5,59,13000
# 6,5000,16000      ← Watermark=13s，[10000,20000) 仍未触发
# 7,8888,23000      ← Watermark=20s ≥ 20000 → 触发 [10000,20000)

# 预期输出：
# 窗口[0~10000) 订单数=1 金额=118.0      ← 8000 乱序单正确归窗
# 窗口[10000~20000) 订单数=5 金额=8556.0 ← 不含 8000

# 要点：8000 到达时 Watermark 还没到 10000 → 窗口未触发 → 还能进窗
