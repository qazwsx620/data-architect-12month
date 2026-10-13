# Day48：DWD 清洗脚本（ODS → DWD，虚拟机实测通过）
# 前置：config.py 需含 DW_CONFIG 指向 dw_project

import pymysql
import pandas as pd
from config import DW_CONFIG

STATUS_MAP = {1: "未支付", 2: "已支付", 3: "已取消"}


def extract_ods(cursor):
    """从 ODS 读取（当前抽全部，重跑可加日期过滤）"""
    cursor.execute(
        "SELECT order_id, user_id, product_id, amount, status, order_date FROM ods_order"
    )
    df = pd.DataFrame(cursor.fetchall(),
                      columns=["order_id", "user_id", "product_id", "amount", "status", "order_date"])
    return df


def transform(df):
    """清洗五步：类型→格式→去重→缺失→映射"""
    # 1. 类型转换
    df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
    # 2. 格式统一（order_date 已是 date，转字符串 YYYY-MM-DD）
    df["order_date"] = pd.to_datetime(df["order_date"]).dt.strftime("%Y-%m-%d")
    # 3. 去重（订单主键）
    df = df.drop_duplicates(subset=["order_id"])
    # 4. 缺失处理
    df["status"] = df["status"].fillna(1).astype(int)
    df["amount"] = df["amount"].fillna(0).round(2)
    # 5. 枚举映射
    df["status_name"] = df["status"].map(STATUS_MAP)
    return df


def load_dwd(df):
    """写入 DWD 明细表（幂等：按 order_id 先删后插）"""
    conn = pymysql.connect(**DW_CONFIG)
    cursor = conn.cursor()
    if len(df) > 0:
        cursor.execute(
            f"DELETE FROM dwd_order_detail WHERE order_id IN (%s)" % ",".join(["%s"] * len(df)),
            df["order_id"].tolist()
        )
        cursor.executemany(
            "INSERT INTO dwd_order_detail(order_id,user_id,product_id,amount,status_name,order_date) "
            "VALUES(%s,%s,%s,%s,%s,%s)",
            df[["order_id", "user_id", "product_id", "amount", "status_name", "order_date"]].values.tolist()
        )
        conn.commit()
        print(f"DWD 写入 {len(df)} 行")
    conn.close()


if __name__ == "__main__":
    conn = pymysql.connect(**DW_CONFIG)
    cursor = conn.cursor()
    df = extract_ods(cursor)
    conn.close()
    df = transform(df)
    load_dwd(df)
