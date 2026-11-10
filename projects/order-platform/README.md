# 订单数仓平台版 — 总体架构

> 模块七（数据平台工程）收官主项目：把调度、元数据、血缘、质量、安全、服务串成一个平台
> 本文件为纸面设计（架构蓝图），实际组件见 `scripts/day86~day96/`

## 一、设计目标

从"工具堆"升级为"平台"：六个组件不是并列铺开，而是围绕**同一套元数据实体**协作，让三条流贯通。

| 流 | 内容 |
|---|---|
| 数据流 | 业务库 → ODS → DWD → DWS → ADS → API/BI |
| 控制流 | 调度触发 → 任务执行 → 质量校验（P0 阻断）→ 重试/告警 |
| 元数据流 | 运行事件、血缘边、质量结果、访问审计 → 回流治理层 |

## 二、五层总体架构

| 层 | 组件 | 选型 | 职责 | 部署 |
|---|---|---|---|---|
| 1 数据接入 | 数据同步 | Python(pymysql) / 生产 DataX | 业务库 → ODS 抽取 | VM / 集群 |
| 2 存储计算 | 离线存储 | MySQL（教学）/ HDFS+Hive（生产） | 分层落表 | VM / 集群 |
| 2 存储计算 | 离线计算 | MySQL SQL（教学）/ Spark（生产） | 清洗、聚合 | VM / 集群 |
| 3 调度编排 | 编排 | Airflow 2.10.3 | DAG 依赖、定时、补数、重试 | 单机 venv |
| 4 数据治理 | 元数据 | DataHub（生产）/ Atlas（强合规 Hive 场景） | 技术+业务元数据、搜索、owner、分级标签 | Docker |
| 4 数据治理 | 血缘 | sqlglot（静态解析）+ OpenLineage（执行侧事件） | 表级/字段级血缘、影响分析 | 脚本 + 事件 |
| 4 数据治理 | 质量 | 自研规则库+引擎（`rules_v2.yaml` + `quality_engine_v2.py`） | 规则配置化、P0 阻断、结果落表、告警 | VM |
| 4 数据治理 | 安全 | Ranger（Hive）/ 视图 + API 注入（MySQL） | RLS/CLS/脱敏/加密/审计 | 平台组件 |
| 5 数据服务 | API | FastAPI + uvicorn（独立 `api_env`） | 指标查询、API Key、限流、脱敏 | VM |
| 5 数据服务 | BI | Superset / Metabase | 看板、自助分析 | Docker |

横向支撑：监控告警、成本治理、运维备份。

## 三、数据流分层

| 层 | 表 | 引擎 | 产出任务 | 频率 |
|---|---|---|---|---|
| ODS | `ods_order` | Python + MySQL | `ods_extract` | 日 01:00 |
| DWD | `dwd_order_detail` | Python/SQL | `dwd_transform` | 日 |
| DWS | `dws_user_daily`、`dws_product_daily` | SQL | `dws_aggregate` | 日 |
| ADS | `ads_gmv_report` | SQL | `ads_report` | 日 |
| 导出 | csv/html | Python | `ads_export` | 日 |
| 校验 | 质量结果表 / `quality_results.json` | Python | `quality_check` | 日 |
| 服务 | ADS 表经 API 暴露 | — | `gmv_api`（只读） | 请求时 |

## 四、组件交互矩阵

| 发起方 | 被调方 | 交互内容 | 协议/方式 | 时机 |
|---|---|---|---|---|
| Airflow | 元数据平台 | 任务运行事件（dag_id/task_id/run_id/状态/产出表） | OpenLineage 事件 / REST | 任务开始、结束 |
| 血缘解析器 | 元数据平台 | 表级/字段级边（source→target） | DataHub API / 元数据库 | 提交时 + 每日跑完 |
| Airflow | 质量引擎 | 触发规则校验 | BashOperator 调 `quality_engine_v2.py` | `quality_check` 节点 |
| 质量引擎 | 元数据平台 | 质量结果挂到表实体（可信度） | 写结果表 + API 回写 | 每次校验后 |
| 权限系统 | 元数据平台 | 拉取表/字段分级标签 → 生成 RLS/CLS 策略 | REST | 策略配置/变更 |
| API 服务 | ADS 库 | 参数化查询 | MySQL 只读账号 | 每次请求 |
| API 服务 | 审计库 | 访问留痕（谁/何时/哪个接口/返回行数） | 写审计表/日志 | 每次请求 |

## 五、架构决策记录（ADR）

### ADR-1 调度选 Airflow
- 背景：四层依赖链、需补数重跑、代码要版本化
- 候选：Airflow / DolphinScheduler / xxl-job
- 结论：**Airflow**
- 理由：Python 栈统一、DAG 即代码可 Git 管理、生态集成好、已验证；xxl-job 表达不了 DAG 依赖，DS 偏可视化配置

### ADR-2 元数据选 DataHub
- 背景：多源（MySQL/Airflow/SQL 脚本）、要可搜索、要血缘
- 候选：Atlas / DataHub
- 结论：**DataHub**
- 理由：连接器覆盖 MySQL/Airflow、UI 现代可搜索、Kafka 元数据事件模型；Atlas 部署重、优势在 Hive Hook 与强合规分级

### ADR-3 服务层只读 ADS + API，不直连 DWD/DWS
- 背景：业务方要 GMV，最省事是直连明细表
- 候选：直连 DWD / 只读 ADS + API
- 结论：**只读 ADS + API**
- 理由：口径固化（指标字典唯一权威）、性能保护（不被大查询拖垮）、权限可控（只读账号 + API Key + 脱敏）、全链路可审计

## 六、四条关键契约

1. 质量是 DAG 内的 task，不是旁挂——P0 失败靠任务失败阻断下游
2. 血缘双通道（静态解析 + 执行侧事件）写同一套元数据实体
3. 元数据是中枢——血缘、质量、权限、服务共用同一套实体
4. 服务层只读 ADS、只走 API

## 七、已有组件索引（对应 scripts）

| 能力 | 产物 |
|---|---|
| 调度 | `scripts/day87/etl_order_dw.py` |
| 平台选型 | `scripts/day88/调度平台选型对比表.md` |
| 元数据方案 | `scripts/day89/元数据平台方案.md` |
| 血缘 | `scripts/day90/lineage_extract.py` |
| 数据服务 | `scripts/day91/gmv_api.py` |
| 指标字典 | `scripts/day92/指标字典.md` |
| 开发规范 | `docs/数仓开发规范.md` |
| 建模规范 | `docs/数仓建模规范.md` |
| 质量平台 | `scripts/day95/rules_v2.yaml`、`quality_engine_v2.py` |
| 安全方案 | `scripts/day96/数仓安全方案.md` |

## 八、运行方式（当前教学环境）

```bash
# 调度（VM）
cd ~/airflow && airflow scheduler -D && airflow webserver -p 8080 -D

# 质量
cd ~/py_learn/etl_project && python3 quality_engine_v2.py

# 血缘
cd ~/py_learn/etl_project && python3 lineage_extract.py

# 服务
cd ~/py_learn/etl_project && ~/api_env/bin/uvicorn gmv_api:app --host 0.0.0.0 --port 8000
```

## 九、后续演进

- 接入 OpenLineage 补齐执行侧血缘盲区
- 质量结果入元数据平台，做表级可信度评分
- 安全策略从"方案"落地为 Ranger 实际策略
- 增加监控大盘（调度成功率/质量通过率/API 错误率）
