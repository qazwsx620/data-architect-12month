#!/usr/bin/env python3
# Day37 演示：Pandas 数据清洗（缺失/去重/类型转换/apply/综合实战）
# 用法：python3 clean_demo.py

import pandas as pd
import numpy as np

# ====== 1. 缺失值处理 ======
df = pd.DataFrame({
    "user_id": [10001, 10002, 10003, 10004],
    "name":    ["张三", "李四", None, "王五"],
    "amount":  [99, None, 199, 299],
    "age":     [20, 22, None, 24],
})
print("isna:\n", df.isna())
print("每列缺失数:\n", df.isna().sum())
print("\ndropna 删行:\n", df.dropna())
print("\nfillna 填充:\n", df.fillna({"name": "未知", "amount": 0, "age": df["age"].mean()}))

# ====== 2. 重复值去重 ======
df2 = pd.DataFrame({
    "user_id": [10001, 10001, 10002, 10002, 10003],
    "name":    ["张三", "张三", "李四", "李四", "王五"],
    "amount":  [99, 99, 199, 199, 299],
})
print("\nduplicated:\n", df2.duplicated())
print("\ndrop_duplicates:\n", df2.drop_duplicates())
print("\n按user_id去重:\n", df2.drop_duplicates(subset=["user_id"]))
print("\nkeep=last:\n", df2.drop_duplicates(keep="last"))

# ====== 3. 类型转换 ======
df3 = pd.DataFrame({
    "user_id": [10001, 10002, 10003],
    "date":    ["2026-10-01", "2026-10-02", "2026/10/03"],
    "amount":  ["99", "abc", "299"],
})
print("\n转换前 dtypes:\n", df3.dtypes)
df3["amount"] = pd.to_numeric(df3["amount"], errors="coerce")
df3["date"] = pd.to_datetime(df3["date"], format="mixed")
print("转换后 dtypes:\n", df3.dtypes)
print("修复后:\n", df3)

# ====== 4. 综合清洗实战（四步流程） ======
raw = pd.DataFrame({
    "user_id": [10001, 10001, 10002, 10003, 10004],
    "name":    ["张三", "张三", "李四", None, "王五"],
    "amount":  ["99", "99", "abc", "199", "299"],
    "date":    ["2026-10-01", "2026-10-01", "2026/10/02", "2026-10-03", "2026-10-04"],
})
print("\n原始数据:\n", raw)

# 1. 类型转换
raw["amount"] = pd.to_numeric(raw["amount"], errors="coerce")
raw["date"] = pd.to_datetime(raw["date"], format="mixed")
# 2. 去重
raw = raw.drop_duplicates()
# 3. 缺失处理
raw["amount"] = raw["amount"].fillna(0)
raw["name"] = raw["name"].fillna("未知")

print("\n清洗后:\n", raw)
