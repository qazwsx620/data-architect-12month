#!/usr/bin/env python3
# Day36 演示：Pandas 核心（Series / DataFrame / loc-iloc / 读取CSV）
# 用法：python3 series_demo.py / df_demo.py / df_index.py

# ====== series_demo.py：Series 与 loc/iloc ======
import pandas as pd

s = pd.Series([100, 200, 300])
print(s)

s2 = pd.Series([100, 200], index=["a", "b"])
print(s2["a"])      # 标签取值 → 100
print(s2.iloc[0])   # 位置取值 → 100
# print(s2[0])      # ❌ KeyError：自定义索引后 [] 按标签找

# ====== df_demo.py：DataFrame 创建与属性 ======
df = pd.DataFrame({
    "user_id": [10001, 10002, 10003],
    "name":    ["张三", "李四", "王五"],
    "amount":  [99, 199, 299],
    "age":     [20, 22, 24],
})
print(df)
print(df.shape)     # (3, 4)
print(df.dtypes)    # 每列类型
print(df.describe())  # count/mean/std/min/25%/50%/75%/max
print(df.info())    # 行数/列/非空/类型/内存

# ====== df_index.py：索引与切片 + 读取CSV ======
print("取name列:\n", df["name"])        # 取一列 → Series
print("loc[0]:\n", df.loc[0])           # 标签行
print("loc[0:1]:\n", df.loc[0:1])       # 闭区间含1
print("iloc[0:2]:\n", df.iloc[0:2])     # 开区间不含2
print("loc[0,'name']:", df.loc[0, "name"])  # 张三
print("iloc[1,2]:", df.iloc[1, 2])          # 199

# 读取CSV（无表头，指定列名）
df2 = pd.read_csv("demo_data.txt", header=None, names=["user_id", "date", "amount"])
print("\n读取CSV:\n", df2)
