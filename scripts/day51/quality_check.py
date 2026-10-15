# Day51 实操：数仓全链路质量校验脚本（虚拟机实测通过）
# 前置：config.py 含 DW_CONFIG 指向 dw_project
# 运行：python3 quality_check.py; echo "exit=$?"
# 机制：任一校验失败 → exit 1（调度系统据此判定任务失败）

import sys
import pymysql
from config import DW_CONFIG


def check(conn, name, sql):
    """执行校验 SQL，返回 (是否通过, 说明)"""
    cursor = conn.cursor()
    cursor.execute(sql)
    bad_count = cursor.fetchone()[0]
    ok = bad_count == 0
    status = "PASS" if ok else "FAIL"
    print(f"[{status}] {name}: 异常数={bad_count}")
    return ok


def run_checks():
    conn = pymysql.connect(**DW_CONFIG)
    results = []

    # 1. ODS：主键唯一
    results.append(check(conn, "ODS-订单主键唯一",
        "SELECT COUNT(*) FROM (SELECT order_id FROM ods_order GROUP BY order_id HAVING COUNT(*)>1) t"))

    # 2. DWD：金额非负 + 金额空值
    results.append(check(conn, "DWD-金额非负",
        "SELECT COUNT(*) FROM dwd_order_detail WHERE amount < 0"))
    results.append(check(conn, "DWD-金额空值",
        "SELECT COUNT(*) FROM dwd_order_detail WHERE amount IS NULL"))

    # 3. DWS：汇总负数
    results.append(check(conn, "DWS-用户汇总金额非负",
        "SELECT COUNT(*) FROM dws_user_daily WHERE total_amount < 0"))

    # 4. ADS：报表负数
    results.append(check(conn, "ADS-GMV非负",
        "SELECT COUNT(*) FROM ads_gmv_report WHERE gmv < 0"))

    conn.close()

    # 告警模拟：任一失败 → exit 1
    if all(results):
        print("\n✅ 全部校验通过")
        return 0
    else:
        print("\n❌ 存在质量问题！请排查（空值/重复/异常金额）")
        return 1


if __name__ == "__main__":
    sys.exit(run_checks())
