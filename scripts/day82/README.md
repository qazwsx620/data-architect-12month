# Day82 实操：调优配置落地 + Web UI 背压观察

## 0. 前置
- 无旧作业（flink list；有 RUNNING 先 cancel）；nc 可用
- 本机 1 TM × 1 slot，并行度无法真正多并行，重点是会写参数 + 会看 UI

## 1. 放入代码并运行
```bash
cp TuningDemo.java ~/py_learn/flink_project/socket_word/src/main/java/com/example/
cd ~/py_learn/flink_project/socket_word
mvn -q package
flink run -c com.example.TuningDemo target/socket-word-1.0.jar
```

## 2. 发数据（另开窗口）
```bash
nc -lk 9999
# 1001,100
# 1001,200
# 1002,50
tail -f /opt/flink/log/flink-vboxuser-taskexecutor-0-Ubuntu-data-dev.out
# 预期：user=1001 累计=100.0 / 300.0；user=1002 累计=50.0
```

## 3. 三项观察
### 3.1 Web UI 背压观察
浏览器 http://localhost:8081 → Running Jobs → TuningDemo → SubTasks
- Backpressure 标签：OK/LOW/HIGH（低流量应为 OK）
- Metrics 标签：Records Received/Sent 速率
- 定位规则：第一条 HIGH 边的下游算子是瓶颈

### 3.2 Checkpoint 目录
```bash
find /tmp/ckpt-tuning -type d | head
```

### 3.3 作业取消
```bash
flink cancel <jobid>
```

## 调优参数速查
| 参数 | 作用 |
|------|------|
| enableCheckpointing(5000, EXACTLY_ONCE) | 间隔 + 精确一次语义 |
| setCheckpointTimeout(60000) | 单次快照超时 |
| setMinPauseBetweenCheckpoints(2000) | 两次快照最小间隔，防挤压 |
| setCheckpointStorage(path) | 快照存储位置（生产 hdfs） |
| setRestartStrategy(fixedDelayRestart(3,5000)) | 失败重启策略 |
| setParallelism(n) | 并行度（受分区数/slot 约束） |
| setStateBackend(RocksDB) | 大状态增量快照 |

## 面试答题链
- CPU 满 → 提瓶颈算子并行度
- 堆 OOM/GC → 调 Heap + 对象复用
- 状态大 → RocksDB 增量快照
- 外部写慢 → 攒批 + 批量 + 异步 IO
- 热点倾斜 → 加盐 + 两阶段聚合
