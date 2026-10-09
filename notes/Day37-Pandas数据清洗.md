# Day37 · Pandas 数据清洗（缺失值 / 去重 / 类型转换 / apply）

> 模块三 · Python 阶段 Day3 | 配套脚本见 `scripts/day37/` 目录，虚拟机实测通过。
> 背景：数据清洗是数据开发日常核心，"脏数据→干净数据"四步流程是面试必答。

---

## 1. 缺失值处理

```python
df.isna()           # 逐格判断缺失
df.isna().sum()     # 每列缺失个数

df.dropna()         # 删除有缺失的行
df.fillna({"name": "未知", "amount": 0, "age": df["age"].mean()})  # 按列填充
```
> 选择思路：缺失占比低→删除影响小可删；行少/缺失多→填充。
> ⚠️ fillna 返回新对象，原地改需 `inplace=True` 或重新赋值。

## 2. 重复值去重

```python
df.duplicated()                          # 逐行标记重复（从第二行起）
df.drop_duplicates()                     # 删除完全重复行
df.drop_duplicates(subset=["user_id"])   # 按指定列去重
df.drop_duplicates(keep="last")          # 保留最后一个
df.drop_duplicates(keep=False)           # 全部重复都删
```

## 3. 类型转换

```python
df["amount"].astype(float)                                # 简单转换
df["amount"] = pd.to_numeric(df["amount"], errors="coerce")  # 安全转换，脏值→NaN
df["date"] = pd.to_datetime(df["date"], format="mixed")      # 混合格式日期
```
> 💥【坑】to_datetime 默认假设格式一致（%Y-%m-%d），遇到 `2026/10/03` 混合格式报 ValueError → 加 `format="mixed"` 逐元素推断；全 ISO8601 用 `format="ISO8601"`。
> to_numeric(errors="coerce")：无法转换的值变 NaN，再配合缺失处理。

## 4. apply 自定义函数

```python
def clean_row(row):
    if pd.isna(row["amount"]):
        row["amount"] = 0
    return row

df = df.apply(clean_row, axis=1)
```
> axis=0 按列（每列应用）/ axis=1 按行（每行应用）——易混，面试常问。

## 5. 综合清洗实战（标准四步）

```python
# 脏数据：缺失 + 重复 + 类型错乱
raw = pd.DataFrame({
    "user_id": [10001, 10001, 10002, 10003, 10004],
    "name":    ["张三", "张三", "李四", None, "王五"],
    "amount":  ["99", "99", "abc", "199", "299"],
    "date":    ["2026-10-01", "2026-10-01", "2026/10/02", "2026-10-03", "2026-10-04"],
})

# 清洗四步：
# 1. 类型转换
raw["amount"] = pd.to_numeric(raw["amount"], errors="coerce")
raw["date"] = pd.to_datetime(raw["date"], format="mixed")
# 2. 去重
raw = raw.drop_duplicates()
# 3. 缺失处理
raw["amount"] = raw["amount"].fillna(0)
raw["name"] = raw["name"].fillna("未知")

print(raw)
# 结果：10001(99) / 10002(0) / 10003(未知,199) / 10004(299)
```
> **数据清洗标准四步：类型转换 → 去重 → 缺失处理 → 校验**（面试必答）。

---

## 今日面试考点清单
1. isna/dropna/fillna？→ 检查/删行/填充
2. 按列去重与 keep？→ subset + keep(first/last/False)
3. to_numeric(errors="coerce")？→ 脏值变 NaN
4. to_datetime 混合格式？→ format="mixed"
5. apply 的 axis？→ 0按列/1按行
6. 清洗四步流程？→ 类型转换→去重→缺失→校验

## 踩坑记录（面试素材）
- to_datetime 混合格式报错 → 加 format="mixed"
- fillna 不原地生效 → 需 inplace 或重新赋值
- to_numeric 直接报错 → 加 errors="coerce" 变 NaN
- axis 混淆 → 0列 1行
- duplicated 从第二行标记 → 首行一定 False
