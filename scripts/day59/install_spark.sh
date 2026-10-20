# Day59 实操①：安装 Java 17 + Spark 3.5.1（单机 local 模式）
# 已在虚拟机验证成功（Spark 3.5.1 + Scala 2.12.18 + Java 17）

# 1. 安装 Java 17
sudo apt update && sudo apt install -y openjdk-17-jdk-headless
java -version

# 2. 下载 Spark 3.5（华为云镜像，断点续传）
cd /tmp
wget -c https://mirrors.huaweicloud.com/apache/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz

# 3. 解压到 /opt/spark
sudo mkdir -p /opt/spark
sudo tar -xzf spark-3.5.1-bin-hadoop3.tgz -C /opt/spark --strip-components=1

# 4. 配置环境变量
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export SPARK_HOME=/opt/spark' >> ~/.bashrc
echo 'export PATH=$SPARK_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 5. 验证
spark-shell --version
