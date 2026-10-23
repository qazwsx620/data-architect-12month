# 大数据版订单数仓 · 全链路设计（纸面，对应模块四 etl_chain.py）

## 1. 调度编排（crontab，每天 02:00）
```
0 2 * * * /home/vboxuser/py_learn/etl_project/odw_project/odw_etl.sh
```
odw_etl.sh 步骤（失败阻断下游，同模块四）：
1) spark-submit 跑 ODS 装载（读 CSV → 写分区 dt=昨天）
2) spark-submit 跑 DWD 清洗（枚举映射）
3) spark-submit 跑 DWS 汇总（已支付口径）
4) spark-submit 跑 ADS 报表（写 MySQL/CSV）
5) 任一失败 → 退出非0，下游不执行（rerun.sh 重跑）

## 2. 质量校验（复用 Day65 quality_engine.py，规则配置化）
- rules.yaml 加 odw 表规则：dwd_order_detail.order_id 唯一 / amount 非负 / 非空率
- 调度在 DWD→DWS 之间插校验：FAIL 即阻断（同模块四 -50 脏数据演示）

## 3. 血缘与字典（复用 Day64）
- lineage.md 加 Hive 层：ods_order(外部表) → dwd_order_detail → dws_* → ads_gmv_report
- data_dictionary.md 加 odw 库分层说明，口径不变

## 4. 与单机版差异总结（面试）
| 维度 | 单机（模块四） | 大数据版（odw） |
|------|---------------|-----------------|
| 存储 | MySQL | HDFS 分区目录（dt/stat_date） |
| 计算 | Pandas/MySQL SQL | Spark SQL/Hive |
| 建表 | MySQL DDL | Hive 外部表+分区 |
| 调度/质量/血缘/字典 | etl_chain.py | 思想完全复用 |

## 可复用四件套（面试）
调度（crontab 失败阻断） / 质量（rules.yaml 规则配置化） / 血缘（lineage.md） / 字典（data_dictionary.md）
