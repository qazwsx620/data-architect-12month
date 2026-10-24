# Day70 实操：OrderWindowCount 运行步骤

# 1. 放入工程（Day69 的 socket_word 工程）：
#    cp OrderWindowCount.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/

# 2. 打包 + 提交（注意：1 TM × 1 slot 只能跑 1 个作业，先 flink list 确认没有旧作业）
cd ~/py_learn/flink_project/socket_word
mvn -q package
flink list   # 有 RUNNING 作业先 flink cancel <jobid>
flink run -c com.example.OrderWindowCount target/socket-word-1.0.jar

# 3. nc 数据源（另一终端），格式 user_id,amount：
nc -lk 9999
# 输入：1001,2999 / 1002,99 / 1003,118 / 1004,399 / 1005,59（间隔 1-2 秒）

# 4. print 输出在 TaskManager .out 日志：
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out

# 踩坑备忘：
# - apply 全量聚合 lambda 泛型推断不出 → 用匿名类 AllWindowFunction
# - 滚动 10s 不重叠；滑动 10s/5s 重叠（同一条订单出现在相邻两个窗口）
# - print 输出看 .out 日志，不在提交终端
