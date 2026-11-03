# Day87：把模块四 etl_chain.py 改造成 Airflow DAG（虚拟机实测跑通）
# 环境：Airflow 2.10.3（venv：~/airflow_env）+ SQLite 元数据库 + WebUI 8080
# 机制：6 个 BashOperator 串行，依赖链表达 = etl_chain.py 的"失败即终止"顺序
# 要点：BashOperator 子进程在临时目录启动，必须 cd 项目目录 + 用 venv python 绝对路径

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

# 项目目录（find 定位到的真实路径）
PROJECT_DIR = "/home/vboxuser/py_learn/etl_project"
# venv 里的 python 绝对路径：BashOperator 子进程里的 python3 会解析到系统
# Python（/usr/bin/python3），那里没有 pymysql/pandas/pyyaml，必须显式指定
PYTHON_BIN = "/home/vboxuser/airflow_env/bin/python"

default_args = {
    "owner": "vboxuser",
    "depends_on_past": False,
    "retries": 1,                          # 失败自动重试 1 次
    "retry_delay": timedelta(minutes=1),
    "start_date": datetime(2026, 11, 3),
}

dag = DAG(
    dag_id="etl_order_dw",
    schedule_interval="0 1 * * *",         # 每天 01:00（cron 五段：分 时 日 月 周）
    default_args=default_args,
    catchup=False,                          # 不补跑历史
    description="订单数仓离线全链路 ODS→DWD→DWS→ADS",
)

# Task1 ODS 抽取（对应 etl_chain.py 第 1 步）
task_ods = BashOperator(
    task_id="ods_extract",
    bash_command=f"cd {PROJECT_DIR} && {PYTHON_BIN} ods_extract.py",
    dag=dag,
)

# Task2 DWD 清洗（第 2 步）
task_dwd = BashOperator(
    task_id="dwd_transform",
    bash_command=f"cd {PROJECT_DIR} && {PYTHON_BIN} dwd_transform.py",
    dag=dag,
)

# Task3 DWS 汇总（第 3 步：mysql 执行 SQL 文件）
task_dws = BashOperator(
    task_id="dws_aggregate",
    bash_command=f"cd {PROJECT_DIR} && mysql --local-infile=1 -uroot -p123456 dw_project < dws_aggregate.sql",
    dag=dag,
)

# Task4 ADS 报表（第 4 步）
task_ads = BashOperator(
    task_id="ads_report",
    bash_command=f"cd {PROJECT_DIR} && mysql --local-infile=1 -uroot -p123456 dw_project < ads_report.sql",
    dag=dag,
)

# Task5 报表导出（第 5 步：两个 python 命令 && 连接）
task_export = BashOperator(
    task_id="ads_export",
    bash_command=f"cd {PROJECT_DIR} && {PYTHON_BIN} ads_export.py && {PYTHON_BIN} ads_report_html.py",
    dag=dag,
)

# Task6 质量校验（第 6 步）
task_check = BashOperator(
    task_id="quality_check",
    bash_command=f"cd {PROJECT_DIR} && {PYTHON_BIN} quality_check.py",
    dag=dag,
)

# 依赖链：与 etl_chain.py 的执行顺序一致（上游失败，下游不执行）
task_ods >> task_dwd >> task_dws >> task_ads >> task_export >> task_check
