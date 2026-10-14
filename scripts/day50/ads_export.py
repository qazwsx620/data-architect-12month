# Day50 实操②：ADS 报表 → CSV 导出（虚拟机实测通过）
# 前置：config.py 含 DW_CONFIG 指向 dw_project

import csv
import pymysql
from config import DW_CONFIG


def export_csv():
    conn = pymysql.connect(**DW_CONFIG)
    cursor = conn.cursor()
    cursor.execute("SELECT stat_date, gmv, order_cnt, avg_amount FROM ads_gmv_report ORDER BY stat_date")
    rows = cursor.fetchall()
    conn.close()

    # 写 CSV（表头 + 数据）
    with open("ads_gmv_report.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["stat_date", "gmv", "order_cnt", "avg_amount"])
        writer.writerows(rows)
    print(f"导出 {len(rows)} 行到 ads_gmv_report.csv")


if __name__ == "__main__":
    export_csv()
