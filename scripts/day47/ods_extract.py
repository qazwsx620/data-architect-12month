# Day47：业务模拟数据 + ODS 抽取脚本（虚拟机实测通过）
# 使用前：config.py 需新增 DW_CONFIG（见笔记）

import pymysql
from config import DW_CONFIG


def get_last_date(cursor):
    """取 ODS 里已有的最大订单日期（增量水位线）"""
    cursor.execute("SELECT COALESCE(MAX(order_date), '1999-01-01') FROM ods_order")
    return cursor.fetchone()[0]


def extract_ods():
    conn = pymysql.connect(**DW_CONFIG)
    cursor = conn.cursor()

    # 增量：只抽上次之后的新订单
    last_date = get_last_date(cursor)
    cursor.execute(
        "SELECT order_id, user_id, product_id, amount, status, order_date "
        "FROM biz_order WHERE order_date > %s", (last_date,)
    )
    rows = cursor.fetchall()

    # 原样入库：显式解包 6 字段 + raw_data（7 个 %s 一一对应）
    for r in rows:
        order_id, user_id, product_id, amount, status, order_date = r
        raw = f"{order_id},{user_id},{product_id},{amount},{status},{order_date}"
        cursor.execute(
            "INSERT INTO ods_order(order_id,user_id,product_id,amount,status,order_date,etl_time,raw_data) "
            "VALUES(%s,%s,%s,%s,%s,%s,NOW(),%s) "
            "ON DUPLICATE KEY UPDATE raw_data=VALUES(raw_data), etl_time=NOW()",
            (order_id, user_id, product_id, amount, status, order_date, raw)
        )
    conn.commit()
    print(f"增量抽取 {len(rows)} 行（上次截至 {last_date}）")
    conn.close()


if __name__ == "__main__":
    extract_ods()
