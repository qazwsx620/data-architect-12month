# Day73 · Kafka 深化（核心概念 + 为什么快 + 本机实操）

> 模块六 · 实时数仓实战 Day6 | 配套脚本见 `scripts/day73/`（README.md 安装与验证步骤）。
> 真实环境：Kafka 3.7.1 @ /opt/kafka，ZK + broker 本地跑通，order_topic 生产消费 + 消费组分摊验证。

---

## 1. 核心概念（面试必答）

| 概念 | 含义 |
|------|------|
| Topic | 消息的逻辑分类（如订单 topic） |
| Partition | 分区 = topic 内的并行单元（分布在不同 broker，读写并行最小单位） |
| offset | 分区内消息的递增序号（消费位置标记） |
| 副本 Replica | 分区的冗余副本（leader 读写 / follower 备份，高可用） |
| 消费组 Consumer Group | 组内消费者分摊分区 |

## 2. 消费组 vs 分区（易混淆坑，面试必答）

```text
规则：一个分区同一时刻同组内只被一个消费者消费
分区数 ≥ 消费者数：消费者全利用（多了的闲置）
例：3 分区 5 消费者 → 2 个闲置
```

## 3. Kafka 为什么快（面试必答 4 点）

```text
① 顺序写磁盘：append-only，无随机 IO（磁盘顺序写≈内存速度）
② 页缓存 PageCache：读写走 OS 页缓存，不直接碰磁盘
③ 零拷贝 Zero Copy：磁盘→网卡，不经用户态拷贝（sendfile）
④ 分区并行：多分区并行读写，吞吐线性扩展
（补充优化：批量压缩——真实存在，核心还是上面 4 点）
```

## 4. 本机实操记录（Kafka 3.7.1 + ZK 模式）

```bash
# 安装：华为云镜像下载解压 /opt/kafka，chown，PATH 写入 ~/.bashrc
# 启动：
/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties   # 终端1
/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties          # 终端2

# 建 topic（3 分区 1 副本）+ 验证：
kafka-topics.sh --create --bootstrap-server 127.0.0.1:9092 --topic order_topic --partitions 3 --replication-factor 1
kafka-topics.sh --list --bootstrap-server 127.0.0.1:9092

# 生产：
kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic

# 消费（无 group 从头读全部）：
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic --from-beginning

# 消费组（同组分摊分区）：
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic order_topic --group my_group
```

### 实测结果（消费组分摊实证）
```text
无 group 消费者：收到全部（1001,2999 / 1002,99 / 1003,118 / 1004,399 / 1005,333）
同组消费者 A：1005,333（分到 1 个分区）
同组消费者 B：1006,199 / 1007,299 / 1008,399（分到 2 个分区）
结论：同一条数据不会被同组两个消费者重复收到
```

## 5. 踩坑记录（本日 3 连）

| 坑 | 现象 | 解法 |
|----|------|------|
| 配置路径被复制污染 | `/opt/kafka/config/shturl.cc/xxx`（短链） | 手动输入文件名 + Tab 补全，不复制粘贴 |
| bootstrap-server 主机名超时 | Timed out waiting for node assignment | 用 127.0.0.1:9092（绕开 Ubuntu-data-dev 解析 127.0.1.1） |
| --group 前缺空格 | topic 名变 order_topic--group → LEADER_NOT_AVAILABLE | 命令手输，注意参数空格 |

> 补充：Kafka 3.x 支持 KRaft 模式（config/kraft，不依赖 ZK），面试可提"新版本 KRaft 取代 ZK"。

---

## 今日面试考点清单
1. 核心概念？→ Topic/分区/offset/副本/消费组
2. 消费组规则？→ 一分区同组一消费者，多了闲置
3. 为什么快？→ 顺序写/页缓存/零拷贝/分区并行
4. 无 group 消费？→ 每次新建独立消费者从头读
5. 同组不重复？→ 每条数据只归所属分区的那个消费者

## 易混淆坑
- 消费组"分摊分区"≠ 广播（广播要不同 group）
- 分区数决定并行上限（消费者再多也闲置）
- bootstrap-server 主机名解析问题优先用 IP
- --group 与 --from-beginning 组合语义不同（组内按 offset 续读）
