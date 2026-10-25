# Day72 实操：KeyedStateCount 运行步骤 + 故障恢复实验

# 1. 放入工程：
#    cp KeyedStateCount.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/

# 2. 打包 + 提交（先确认无旧作业）
cd ~/py_learn/flink_project/socket_word
mvn -q package
flink list   # 有 RUNNING 先 flink cancel <jobid>
flink run -c com.example.KeyedStateCount target/socket-word-1.0.jar

# 3. 跟踪输出（另一终端）：
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out

# 4. nc 数据源（user_id,amount）：
nc -lk 9999
# 1001,2999  → user=1001 累计=2999.0
# 1001,99    → user=1001 累计=3098.0
# 1002,118   → user=1002 累计=118.0
# 1001,400   → user=1001 累计=3498.0

# 5. 故障实验（核心教学点）：
#    另一终端杀掉 TaskManager：
#    pkill -9 -f TaskManagerRunner
#    → 观察：作业不会自动恢复（standalone TM 是静态资源，被杀不自动拉起）
#    → 根因：作业重启也拿不到 slot → 3 次重试耗尽 → FAILED
#    → 生产用 YARN/K8s：资源管理器自动拉起 TM，作业可自动恢复

# 6. 恢复：手动拉起 TM
#    /opt/flink/bin/taskmanager.sh start
#    jps   # 出现 TaskManagerRunner
#    作业已 FAILED 则重新提交；本地模式 checkpoint 文件在 /tmp flink 临时目录
