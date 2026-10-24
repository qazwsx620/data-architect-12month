# Day69 实操：socket-word 运行步骤

# 1. 工程结构
#   pom.xml + src/main/java/com/example/SocketWordCount.java

# 2. 编译打包（装 Maven）
sudo apt install -y maven
cd ~/py_learn/flink_project/socket_word
mvn -q package

# 3. 终端 A：起 socket 数据源并输入
nc -lk 9999
# 输入：hello flink / hi world

# 4. 终端 B：启动集群 + 提交
start-cluster.sh          # 若 8081 连接拒绝 = 集群没起
jps                       # 确认 StandaloneSessionClusterEntrypoint + TaskManagerRunner
flink run -c com.example.SocketWordCount target/socket-word-1.0.jar

# 5. 看输出（writeAsText 单并行 = 单文件，不是目录）
cat /tmp/flink_socket_out
# (hello,1) (flink,1) (hi,1) (world,1)

# 踩坑备忘：
# - Lambda 返回 Tuple2 → 类型擦除 → .returns(Types.TUPLE(Types.STRING, Types.INT))
# - NoResourceAvailable = TM 未注册完，看日志确认 RUNNING 再等
# - 重复 start-cluster 会产生多个 taskexecutor 日志文件（-0/-1），先 stop-cluster.sh
