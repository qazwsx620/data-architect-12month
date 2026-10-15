# Day52 实操①：全链路编排主控脚本（虚拟机实测通过）
# 依赖：config.py(DW_CONFIG)、ods_extract.py、dwd_transform.py、quality_check.py
#       dws_aggregate.sql、ads_report.sql（etl_project 目录下）
# 用法：python3 etl_chain.py
# 机制：上游失败立即退出，下游不执行（依赖阻断）

import subprocess
import sys


def run_step(name, cmd):
    """执行一个步骤；失败立即退出（下游阻断）"""
    print(f"\n===== {name} =====")
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        print(f"❌ {name} 失败（exit={result.returncode}），终止链路，下游不执行")
        sys.exit(1)
    print(f"✅ {name} 成功")
    return True


def main():
    # DWS/ADS 用 mysql 命令行执行 SQL 文件（密码本地练习环境）
    steps = [
        ("ODS抽取",    "python3 ods_extract.py"),
        ("DWD清洗",    "python3 dwd_transform.py"),
        ("DWS汇总",    "mysql --local-infile=1 -uroot -p123456 dw_project < dws_aggregate.sql"),
        ("ADS报表",    "mysql --local-infile=1 -uroot -p123456 dw_project < ads_report.sql"),
        ("报表导出",   "python3 ads_export.py && python3 ads_report_html.py"),
        ("质量校验",   "python3 quality_check.py"),
    ]
    for name, cmd in steps:
        run_step(name, cmd)
    print("\n🎉 全链路执行完成")


if __name__ == "__main__":
    main()
