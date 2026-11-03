# Day87 总结笔记：Airflow 实操——etl_chain.py 改造为 DAG

> 日期：2026-11-03 ｜ 模块七：数据平台工程 ｜ 状态：✅ 虚拟机跑通

## 一、今天做了什么

把模块四的离线 ETL 主控脚本 `etl_chain.py`（subprocess 顺序执行 + 失败退出）改造成 Airflow DAG，并完整跑通：

1. **装 Airflow 2.10.3**：venv 隔离 + SQLite 元数据库 + admin 账号 + Scheduler/WebUI（8080）
2. **改造 DAG**：6 个 BashOperator 串行，依赖链表达执行顺序
3. **调度 + WebUI 确认**：Graph 视图 6 节点链可视化、手动触发跑通全链路

## 二、DAG 结构（scripts/day87/etl_order_dw.py）

| Task | 对应 etl_chain.py 步骤 | 类型 | 命令要点 |
|---|---|---|---|
| ods_extract | ODS抽取 | BashOperator | `cd 项目目录 && venv python ods_extract.py` |
| dwd_transform | DWD清洗 | BashOperator | 同上 |
| dws_aggregate | DWS汇总 | BashOperator | `mysql --local-infile=1 ... < dws_aggregate.sql` |
| ads_report | ADS报表 | BashOperator | 同上（ads_report.sql） |
| ads_export | 报表导出 | BashOperator | 两个 python 命令 `&&` 连接 |
| quality_check | 质量校验 | BashOperator | `venv python quality_check.py` |

依赖链：`task_ods >> task_dwd >> task_dws >> task_ads >> task_export >> task_check`（5 个 `>>`，全串行）

## 三、踩坑记录（面试高频）

### 坑 1：`ModuleNotFoundError: No module named 'pymysql'`
- **现象**：ods_extract 失败，日志显示 `import pymysql` 挂
- **Root cause**：BashOperator 子进程是 `/usr/bin/bash -c '... python3 ...'`，`python3` 解析到**系统 Python（/usr/bin/python3）**，不是 venv——依赖根本没装进那个环境
- **修法**：DAG 里定义 `PYTHON_BIN = "/home/vboxuser/airflow_env/bin/python"`，所有 bash_command 用它代替 `python3`
- **教训**：Airflow 任务在独立子进程跑，Python 环境、依赖必须显式管理

### 坑 2：`ModuleNotFoundError: No module named 'pandas'`
- venv 缺 pandas → `pip install pandas`
- 顺带用 `grep -hE "^(import|from) " *.py | sort -u` 全量盘点依赖，发现隐藏坑 `yaml`（config.py 读配置用）→ `pip install pandas pyyaml`

### 坑 3（潜在）：依赖盘点
- 生产上应写成 `requirements.txt` 统一管理，而不是"缺啥补啥"

## 四、核心知识点

1. **BashOperator 执行环境**：子进程在临时目录（`/tmp`）启动，当前目录不是项目 → 必须 `cd {PROJECT_DIR} &&`；相对路径在 etl_chain.py 里能用是因为"你本来就在项目目录下运行"
2. **路径处理本质区别**：etl_chain.py 的 subprocess 继承当前进程 cwd；BashOperator 不继承，要显式 cd
3. **环境隔离**：Ubuntu 24.04 直接 pip3 install 到系统 Python 会被 PEP 668（externally-managed-environment）拒绝；Airflow 依赖几百个包，必须 venv 隔离
4. **手动触发**：`airflow dags trigger <dag_id>`，run_id 前缀 `manual__` 表示外部手动触发，自动调度为 `scheduled__`
5. **schedule_interval**：`"0 1 * * *"` = cron 五段（分 时 日 月 周），每天 01:00
6. **并行表达**：Airflow 并行用列表 fan-out `[task_a, task_b]`，不是 shell 的 `&&`
7. **WebUI**：Graph 视图可视化依赖（crontab 没有）；Grid 视图看每个 run/task 状态；task → Log 排错

## 五、今日小测试错题

- Q2：BashOperator 本质区别是**执行目录不同**（临时目录 vs 项目目录），必须 cd
- Q3：并行用 `[task_export, task_check]` 列表，不是 `&&`
- Q5：venv 最硬理由是 PEP 668 拒绝 + Airflow 依赖体量大

## 六、明日预告

模块七继续（按计划表 Day88 内容）
