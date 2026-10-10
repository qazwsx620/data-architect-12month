#!/usr/bin/env python3
# Day42 ETL 实战项目：CSV 脏数据 → Pandas 清洗 → MySQL → 幂等写入
# 用法：cd scripts/day42 && python3 etl.py
# 依赖：pymysql（pip3 install pymysql --break-system-packages）
# MySQL：root/123456，库 test_db，表 etl_orders（见本目录 etl_init.sql）

import pandas as pd
import pymysql

# ===== E: 抽取 =====
df = pd.read_csv("input/orders.csv")
print("原始数据行数:", len(df))

# ===== T: 转换清洗（标准四步：类型转换→去重→缺失→校验）=====
# 1. 类型转换（先转类型再去重，去重依赖字段类型一致）
df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
df["create_date"] = pd.to_datetime(df["create_date"], format="mixed").dt.strftime("%Y-%m-%d")

# 2. 去重
df = df.drop_duplicates(subset=["order_id"])
print("去重后行数:", len(df))

# 3. 缺失处理
df["status"] = df["status"].fillna(1).astype(int)
df["amount"] = df["amount"].fillna(0).round(2)

# 4. 校验
print("\n清洗后数据:")
print(df)
print("\n数据质量检查-金额为空:", df["amount"].isna().sum())

# ===== L: 加载到 MySQL（幂等：先删后插）=====
conn = pymysql.connect(
    host="127.0.0.1", user="root", password="123456",
    database="test_db", charset="utf8mb4"
)
cursor = conn.cursor()

# 先删已存在的 order_id（幂等关键）
cursor.execute(
    "DELETE FROM etl_orders WHERE order_id IN (%s)" % ",".join(["%s"] * len(df)),
    df["order_id"].tolist()
)

# 插入
cursor.executemany(
    "INSERT INTO etl_orders(order_id, user_id, amount, status, create_date) "
    "VALUES (%s, %s, %s, %s, %s)",
    df[["order_id", "user_id", "amount", "status", "create_date"]].values.tolist()
)
conn.commit()
print(f"\n成功写入 {cursor.rowcount} 行到 etl_orders")

# 校验：回查
cursor.execute("SELECT COUNT(*) FROM etl_orders")
print("etl_orders 总行数:", cursor.fetchone()[0])
conn.close()
