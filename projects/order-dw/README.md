# 订单数仓项目（Order Data Warehouse）

> 模块四（Day44-55）完整项目：从业务数据到报表的全链路数仓，单机 MySQL 版，可运行、可讲解、可复述。

---

## 1. 架构图

```
业务源表                     数仓四层                             最终去向
biz_user ──────┐
biz_product ───┤ 增量/全量   ods_order ──→ dwd_order_detail ──→ dws_user_daily ──→ ads_gmv_report ──→ CSV
biz_order ─────┴──→ 抽取        (原样)         (清洗五步)      (用户-日汇总)      (每日GMV报表)      HTML
                                        └─→ dws_product_daily ──→ (预留商品报表)     质量校验 exit code
```

## 2. 表清单（dw_project 库，8 表）

| 层 | 表名 | 粒度 | 说明 |
|----|------|------|------|
| DIM | dim_user / dim_product | 每行一实体 | 维度表 |
| FACT | fact_order | 每单一行 | 订单事实（外键+指标） |
| ODS | ods_order | 每单一行 | 原样入库+etl_time+raw_data |
| DWD | dwd_order_detail | 每单一行 | 清洗规范化（status_name 可读） |
| DWS | dws_user_daily | 用户-日 | 订单数/金额（GMV 口径） |
| DWS | dws_product_daily | 商品-日 | 订单数/金额（GMV 口径） |
| ADS | ads_gmv_report | 天 | GMV/订单量/客单价 |

业务源表：biz_user(10) / biz_product(5) / biz_order(8+)

## 3. 脚本清单（scripts/day44-53）

| 脚本 | 职责 |
|------|------|
| config.py | 配置（DB_CONFIG/DW_CONFIG） |
| ods_extract.py | ODS 增量抽取（水位线） |
| dwd_transform.py | DWD 清洗五步 |
| dws_aggregate.sql | DWS 汇总（用户/商品日） |
| ads_report.sql | ADS 每日报表 |
| ads_export.py | 导出 CSV |
| ads_report_html.py | 生成 HTML 可视化报表 |
| quality_check.py | 质量校验（exit code 告警） |
| etl_chain.py | 全链路编排主控 |
| rerun.sh | 一键重跑（幂等） |
| setup_crontab.sh | crontab 定时（每天 02:00） |

## 4. 运行方式（虚拟机）

```bash
# 一次性全链路
cd ~/py_learn/etl_project && python3 etl_chain.py

# 一键重跑（幂等）
./rerun.sh

# 定时调度（每天 02:00）
bash setup_crontab.sh
```

## 5. 口径与规则
- **GMV = 已支付（status=2）订单金额合计**；订单量 = 已支付笔数；客单价 = GMV ÷ 订单量
- 状态映射：1=未支付、2=已支付、3=已取消
- 幂等：DWD 先删后插、DWS/ADS TRUNCATE 重算

## 6. 质量保障
- 每层 ETL 后校验（空值率/主键唯一/金额异常）
- 校验失败 exit=1 → 链路终止 → 告警+人工介入
- 血缘可反查（业务库→ODS→DWD→DWS→ADS）

## 7. 踩坑记录（15 个，面试素材）
LOAD DATA local_infile / 连错库 / execute 参数缺失 / 表缺列 ALTER /
枚举映射 status 记混（错2次）/ drop_duplicates 拼写 / 子查询缺列 / 全角引号 /
SQL 文件缺失失败阻断 / 脏数据 -50 逐层传染 / crontab 无重试 /
不幂等翻倍 / 客单价"每顾客" / rerun.sh 笔误 / 校验放最后

## 8. 与真实数仓工程差距（诚实声明）
单机 MySQL + crontab，数据量小；真实生产为 Hive/Spark + Airflow + 分布式存储。
原理一致（分层/口径/幂等/调度），工具迁移即可。
