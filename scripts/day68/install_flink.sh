# Day68 实操：Flink 1.19 本机安装 + 流式 WordCount

# ===== 1. 下载安装（华为云镜像） =====
cd /opt
sudo wget https://mirrors.huaweicloud.com/apache/flink/flink-1.19.1/flink-1.19.1-bin-scala_2.12.tgz
sudo tar -xzf flink-1.19.1-bin-scala_2.12.tgz
sudo mv flink-1.19.1 flink

# 环境变量
echo 'export FLINK_HOME=/opt/flink' >> ~/.bashrc
echo 'export PATH=$FLINK_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# ===== 2. 踩坑修复：/opt/flink 属主改普通用户（否则写不了 log） =====
sudo chown -R vboxuser:vboxuser /opt/flink

# ===== 3. 启动本地集群 + 验证 =====
start-cluster.sh
jps
# 预期：
#   StandaloneSessionClusterEntrypoint  -> JobManager
#   TaskManagerRunner                   -> TaskManager
# Web UI: http://localhost:8081

# ===== 4. 流式 WordCount =====
echo -e "hello flink\nhello spark\nhello world" > /tmp/words.txt
flink run /opt/flink/examples/streaming/WordCount.jar --input /tmp/words.txt --output /tmp/wc_out

# 输出是"目录/时间桶/part 文件"（同 Spark coalesce 输出）
ls /tmp/wc_out/2026-10-24--06/
cat /tmp/wc_out/2026-10-24--06/part-*
# (hello,1) (flink,1) (hello,2) (spark,1) (hello,3) (world,1)
# hello 1->2->3 = 流式有状态累计：来一条处理一条
