# Day36 · Pandas 核心：Series 与 DataFrame（创建 / 属性 / 索引切片 / 读取CSV）

> 模块三 · Python 阶段 Day2 | 配套脚本见 `scripts/day36/` 目录，虚拟机实测通过。
> 背景：Pandas 是数据开发/ETL 的核心工具，loc/iloc 与索引规则是面试高频。

---

## 1. 安装与验证

```bash
pip3 install pandas
# Ubuntu 24.04 若报 externally-managed-environment：
pip3 install pandas --break-system-packages
# 验证
python3 -c "import pandas as pd; print(pd.__version__)"
```

## 2. Series：一维带标签数组

```python
import pandas as pd
s = pd.Series([100, 200, 300])          # 默认索引 0,1,2
s2 = pd.Series([100, 200], index=["a","b"])

print(s2["a"])       # 标签取值 → 100 ✅
# print(s2[0])       # ❌ KeyError：自定义索引后 [] 按标签找，索引里没有 0
print(s2.iloc[0])    # 按位置取值 → 100 ✅
print(s2.loc["a"])   # 按标签取值 → 100 ✅
```

> 💥【坑】自定义索引后，`s2[0]` 是按**标签**找不是位置 → KeyError。**loc 按标签（label）、iloc 按位置（integer）**，Pandas 核心区分。

## 3. DataFrame：二维表格

```python
df = pd.DataFrame({
    "user_id": [10001, 10002, 10003],
    "name":    ["张三", "李四", "王五"],
    "amount":  [99, 199, 299],
    "age":     [20, 22, 24],
})
```

### 常用属性

| 属性 | 作用 |
|------|------|
| df.shape | (行数, 列数) |
| df.columns | 列名列表 |
| df.dtypes | 每列数据类型 |
| df.head(n) | 前n行（默认5） |
| df.describe() | count/mean/std/min/25%/50%/75%/max |
| df.info() | 行数/列/非空/类型/内存 |

## 4. 索引与切片（loc vs iloc）

| 写法 | 含义 |
|------|------|
| df["name"] | 取一列（Series） |
| df.loc[0] | 按标签取行 |
| df.loc[0:1] | 标签切片，**闭区间含末尾** |
| df.iloc[0] | 按位置取行 |
| df.iloc[0:2] | 位置切片，**开区间不含末尾** |
| df.loc[0,"name"] | 行列组合取单值 |
| df.iloc[1,2] | 位置组合取单值 |

> ⚠️【易混】loc 闭区间（含末尾）/ iloc 开区间（不含末尾）。

## 5. 读取 CSV

```python
# 无表头：header=None + names 自定义列名
df2 = pd.read_csv("demo_data.txt", header=None, names=["user_id","date","amount"])
print(df2.head())
```

---

## 今日面试考点清单
1. Series vs DataFrame？→ 一维带标签 / 二维带标签表格
2. loc vs iloc？→ 标签 / 位置
3. loc[0:1] vs iloc[0:2]？→ 闭区间 / 开区间
4. describe() 统计量？→ count/mean/std/min/25%/50%/75%/max
5. read_csv 无表头？→ header=None + names 自定义列名

## 踩坑记录（面试素材）
- 自定义索引后 s2[0] KeyError → 按标签找，用 iloc 按位置
- loc/iloc 区间混淆 → 闭区间 vs 开区间
- read_csv 无表头没设置 → 第一行被当表头
- describe() 漏分位数 → 25%/50%/75% 也是输出
- df["name"] 返回 Series 而非 DataFrame → 取一列是 Series
