# Day68 · Flink 概念与环境安装（流批对比 + 架构 + 本机安装跑通 WordCount）

> 模块六 · 实时数仓实战 Day1 | 配套脚本见 `scripts/day68/`。
> 真实环境：Flink 1.19.1 本机安装（华为云镜像），本地集群 + 流式 WordCount 跑通。

---

## 1. 流处理 vs 批处理（面试必答）

```text
批处理：数据先落库/落盘，按批计算（T+1）→ 有界数据，算完结束（Spark 离线）
流处理：数据持续产生，来一条处理一条 → 无界数据，永不停（Flink）
```
> 实时数仓用流处理，离线数仓用批处理。

## 2. Flink 架构（核心组件）

| 组件 | 职责 | 类比 |
|------|------|------|
| JobManager | 作业调度、检查点协调、故障恢复 | 大脑（一个作业一个） |
| TaskManager | 真正执行计算，含若干 slot | 工人（多个） |
| Client | 提交作业入口 | 提交者 |

```text
用户提交 → Client → JobManager（生成执行图、分配任务）→ TaskManager × N
```

### slot vs 并行度（易混淆坑）
- **slot**：TaskManager 的物理计算槽位 → 决定该 TM 能跑多少并行任务
- **并行度**：算子被拆成几个并行子任务（逻辑拆分）→ 作业总并行度 ≤ 集群总 slot 数

## 3. 实操：本机安装 Flink 1.19 + WordCount

### 安装
```bash
cd /opt
sudo wget https://mirrors.huaweicloud.com/apache/flink/flink-1.19.1/flink-1.19.1-bin-scala_2.12.tgz
sudo tar -xzf flink-1.19.1-bin-scala_2.12.tgz
sudo mv flink-1.19.1 flink
echo 'export FLINK_HOME=/opt/flink' >> ~/.bashrc
echo 'export PATH=$FLINK_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### 启动 + 验证
```bash
# 踩坑：/opt/flink 是 root 解压，普通用户写不了 log → chown
sudo chown -R vboxuser:vboxuser /opt/flink
start-cluster.sh
jps
# 5219 StandaloneSessionClusterEntrypoint（= JobManager）
# 5819 TaskManagerRunner（= TaskManager）
# Web UI: http://localhost:8081
```

### 流式 WordCount
```bash
echo -e "hello flink\nhello spark\nhello world" > /tmp/words.txt
flink run /opt/flink/examples/streaming/WordCount.jar --input /tmp/words.txt --output /tmp/wc_out
```

**输出结构**（流式输出 = 目录/时间桶/part 文件，同 Spark coalesce 输出）：
```bash
ls /tmp/wc_out/2026-10-24--06/
cat /tmp/wc_out/2026-10-24--06/part-*
# (hello,1) (flink,1) (hello,2) (spark,1) (hello,3) (world,1)
```

**流特性实证**：hello 出现 3 次输出 3 次（1→2→3 有状态累计）——**来一条处理一条、实时更新**；批处理会一次输出 `(hello,3)`。

---

## 今日面试考点清单
1. 批 vs 流？→ 有界算完结束 vs 无界永不停
2. JobManager 三职责？→ 调度/检查点/故障恢复
3. TaskManager？→ 真算数的工人，slot 物理槽位
4. slot vs 并行度？→ 物理槽位 vs 逻辑拆分；总并行度 ≤ 总 slot
5. 流式输出？→ 目录/时间桶/part（同 Spark）

## 易混淆坑
- Flink 输出是"目录+part"，不是单文件
- /opt 下 sudo 解压的软件要 chown 才可写
- slot ≠ 并行度（物理 vs 逻辑）
- StandaloneSessionClusterEntrypoint = JobManager 进程名
