#!/usr/bin/env python3
# Day38 演示：Pandas 分组聚合与合并（groupby/agg/merge/concat/SQL对照）
# 用法：python3 group_merge_demo.py

import pandas as pd

# ====== 1. groupby 分组聚合 ======
orders = pd.DataFrame({
    "user_id": [10001, 10001, 10002, 10002, 10003],
    "amount":  [99, 199, 299, 59, 399],
    "status":  [1, 2, 1, 1, 2],
})
print("orders:\n", orders)

# 单列多聚合
print("\n单列多聚合:\n", orders.groupby("user_id")["amount"].agg(["count", "sum", "mean", "max"]))

# 多列不同聚合
print("\n多列不同聚合:\n", orders.groupby("user_id").agg(
    total = ("amount", "sum"),
    avg   = ("amount", "mean"),
    status_max = ("status", "max"),
))

# ====== 2. merge 连接 ======
users = pd.DataFrame({
    "user_id": [10001, 10002, 10003, 10004],
    "name":    ["张三", "李四", "王五", "赵六"],
    "city":    ["南昌", "上海", "北京", "深圳"],
})
print("\ninner join:\n", pd.merge(orders, users, on="user_id", how="inner"))
print("\nleft join:\n", pd.merge(orders, users, on="user_id", how="left"))

# ====== 3. concat 拼接 ======
order_a = orders.iloc[:2]
order_b = orders.iloc[2:]
print("\nconcat 纵向拼接:\n", pd.concat([order_a, order_b], ignore_index=True))

# ====== 4. groupby + reset_index 后 concat ======
result = orders.groupby("user_id")["amount"].sum().reset_index()
print("\n分组结果 reset_index:\n", result)
print("\nconcat 分组结果:\n", pd.concat([result, result], ignore_index=True))
