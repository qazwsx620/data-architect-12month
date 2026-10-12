# ===== etl_utils.py：逻辑层（抽取/清洗/加载）=====
import pandas as pd
import pymysql
from config import DB_CONFIG


def extract(input_file):
    """E: 抽取"""
    return pd.read_csv(input_file)


def transform(df):
    """T: 转换（清洗四步：类型→去重→缺失→校验）"""
    df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
    df["create_date"] = pd.to_datetime(df["create_date"], format="mixed").dt.strftime("%Y-%m-%d")
    df = df.drop_duplicates(subset=["order_id"])
    df["status"] = df["status"].fillna(1).astype(int)
    df["amount"] = df["amount"].fillna(0).round(2)
    return df


def load(df, table="etl_orders"):
    """L: 加载（幂等：先删后插）"""
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()
    cursor.execute(
        f"DELETE FROM {table} WHERE order_id IN (%s)" % ",".join(["%s"] * len(df)),
        df["order_id"].tolist()
    )
    cursor.executemany(
        f"INSERT INTO {table}(order_id, user_id, amount, status, create_date) "
        "VALUES (%s, %s, %s, %s, %s)",
        df[["order_id", "user_id", "amount", "status", "create_date"]].values.tolist()
    )
    conn.commit()
    rows = cursor.rowcount
    conn.close()
    print(f"写入 {rows} 行")
    return rows
