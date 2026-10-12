# Day45 演示：订单数仓 DAG 设计（Airflow 伪代码，理解结构即可）
# 生产环境需安装 Airflow；本文件用于学习 DAG 概念与依赖编排。

from airflow import DAG
from airflow.operators.python import PythonOperator

# 四个任务对应的实际函数（Day47-50 逐步实现）
def run_extract():    # ODS：抽取业务数据
    print("抽取 → ODS")
def run_transform():  # DWD：清洗规范化
    print("清洗 → DWD")
def run_aggregate():  # DWS：主题汇总
    print("汇总 → DWS")
def run_report():     # ADS：生成报表
    print("报表 → ADS")

# DAG：每天2点调度，失败重试3次间隔5分钟
with DAG(
    "order_etl_dag",
    schedule="0 2 * * *",
    default_args={"retries": 3, "retry_delay": 300},   # 300秒=5分钟
) as dag:
    extract_ods   = PythonOperator(task_id="extract_ods",   python_callable=run_extract)
    transform_dwd = PythonOperator(task_id="transform_dwd", python_callable=run_transform)
    aggregate_dws = PythonOperator(task_id="aggregate_dws", python_callable=run_aggregate)
    report_ads    = PythonOperator(task_id="report_ads",    python_callable=run_report)

    # 依赖链：上游先跑，下游等上游；失败阻断下游
    extract_ods >> transform_dwd >> aggregate_dws >> report_ads

# 要点回顾：
# 1. schedule="0 2 * * *"：每天凌晨2点（cron 语法）
# 2. retries=3 + retry_delay=300：失败自动重试3次，间隔5分钟
# 3. >> 定义依赖：extract → transform → aggregate → report
# 4. 上游失败：retries 用完 → 告警 + 人工介入，下游不执行
