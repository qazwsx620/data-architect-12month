# Day90 总结笔记：血缘自动化

> 日期：2026-11-06 ｜ 模块七：数据平台工程 ｜ 状态：✅ 理论 + sqlglot 实操跑通

## 一、血缘自动采集两条路线

| 路线 | 手段 | 优点 | 盲区/缺点 |
|---|---|---|---|
| **执行侧**（事后） | Hive Hook、Spark Listener、Flink lineage、**OpenLineage** | 真实执行血缘（动态 SQL/临时表/UDF 也覆盖） | 侵入引擎；只能采"跑过"的任务；换引擎要重接 |
| **解析侧**（事前） | SQL 文本 → AST（sqlglot 等） | 不依赖执行、CI 可算；轻量 | 动态 SQL/变量拼名解析不到；多方言；只能覆盖"有 SQL 的任务" |

生产上两条互补，互相校验。

## 二、SQL 解析三要素与五个难点

三要素：**写入目标（Target）+ 读取来源（Source）+ 关系方向（source → target）**

例：`INSERT INTO dws_user_daily SELECT ... FROM dwd_order_detail JOIN dim_user ...`
→ 边：`dwd_order_detail → dws_user_daily`、`dim_user → dws_user_daily`

五个难点：
1. 动态 SQL / 变量拼接（`INSERT INTO ${table}`）——解析时目标未知
2. CTE（WITH）——逻辑表名不是物理表，要穿透
3. 子查询/嵌套/UNION——来源藏内层，易漏分支
4. 方言差异（Hive/MySQL/Spark）——要按方言选解析器
5. 跨语句/非标准（INSERT OVERWRITE、MERGE、临时表）——单条 SQL 看不全

补充高频追问：**表级血缘 vs 字段级血缘**（列映射/别名/聚合，难度高一个量级）。

## 三、工具选型

| 工具 | 定位 | 说明 |
|---|---|---|
| sqlparse | 分词/格式化 | **不是血缘解析器**，不做语义解析 |
| **sqlglot** | Python AST 解析器，多方言 | 推荐：能提 target/source、支持 CTE/子查询 |
| Apache Calcite | JVM SQL 解析框架 | 工业级但重（Java 栈） |
| OpenLineage | 血缘事件**规范** | 不是解析器，靠引擎/调度发事件 |

## 四、实操结果（scripts/day90/lineage_extract.py）

解析 `etl_project/*.sql`：**3 条边**
```
dwd_order_detail --> dws_user_daily
dwd_order_detail --> dws_product_daily
dws_user_daily  --> ads_gmv_report
```

对比 Day64 手画 8 条，**漏 5 条，全部是"非 SQL 任务"盲区**：
- `biz_order → ods_order`、`biz_user → dim_user`、`biz_product → dim_product`（Python 抽数/维表加载）
- `ods_order → dwd_order_detail`（DWD 清洗 SQL 写在 Python 字符串里）
- `ads_gmv_report → csv/html`（Python 导出）

生产补法：执行侧 Hook/OpenLineage 补真实血缘；把 SQL 模板化抽成 `.sql` 文件提高静态覆盖率。

## 五、面试答案

**血缘自动采集怎么做**：执行侧（Hook/Listener/OpenLineage）+ 解析侧（SQL AST，如 sqlglot），互补校验。
**SQL 解析难点**：动态 SQL → CTE 穿透 → 子查询/UNION 分支 → 方言 → 表级 vs 字段级。

## 六、今日小测试（5 题全过）

1. 两条路线及盲区 2. 三要素+示例边 3. CTE 要穿透逻辑名 4. sqlparse 分词 vs sqlglot AST 5. 盲区 3/8 是"非 SQL 任务"，执行侧补

## 七、易混淆坑

- sqlparse ≠ 血缘解析器（只分词/格式化）
- OpenLineage 是协议，不是解析工具
- 静态解析天然有盲区（非 SQL 任务、动态 SQL），必须配合执行侧
- 自动解析覆盖率要"和手画/执行侧对账"，静默漏边比报错更危险

## 八、明日预告

模块七继续（按计划表 Day91 内容）
