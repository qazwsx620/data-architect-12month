# Day38 · Pandas 分组聚合与合并（groupby / agg / merge / concat / SQL对照）

> 模块三 · Python 阶段 Day4（Pandas 收尾）| 配套脚本见 `scripts/day38/` 目录，虚拟机实测通过。
> 背景：分组聚合与连接是数据处理核心，Pandas 与 SQL 对应关系是面试高频必背。

---

## 1. groupby 分组聚合（对应 GROUP BY）

```python
orders = pd.DataFrame({
    "user_id": [10001, 10001, 10002, 10002, 10003],
    "amount":  [99, 199, 299, 59, 399],
    "status":  [1, 2, 1, 1, 2],
})

# 单列多聚合
orders.groupby("user_id")["amount"].agg(["count", "sum", "mean", "max"])

# 不同列不同聚合（("列名","函数") 元组命名）
orders.groupby("user_id").agg(
    total = ("amount", "sum"),
    avg   = ("amount", "mean"),
    status_max = ("status", "max"),
)
```
> 对照 SQL：`SELECT user_id, COUNT(*), SUM(amount) FROM orders GROUP BY user_id`。

## 2. merge 连接（对应 JOIN）

```python
users = pd.DataFrame({
    "user_id": [10001, 10002, 10003, 10004],
    "name":    ["张三", "李四", "王五", "赵六"],
    "city":    ["南昌", "上海", "北京", "深圳"],
})

pd.merge(orders, users, on="user_id", how="inner")  # INNER JOIN
pd.merge(orders, users, on="user_id", how="left")   # LEFT JOIN
```

| how | 对应 SQL | 含义 |
|-----|----------|------|
| inner | INNER JOIN | 两边都有才保留 |
| left | LEFT JOIN | 左表全保留，右表缺失→NaN |
| right | RIGHT JOIN | 右表全保留 |
| outer | FULL OUTER JOIN | 两边都保留 |

## 3. concat 拼接（对应 UNION ALL）

```python
pd.concat([df1, df2], ignore_index=True)   # 纵向堆叠，索引重编号
pd.concat([df1, df2], axis=1)              # 横向拼列
```

## 4. Pandas 与 SQL 对照表（面试必背）

| SQL | Pandas |
|-----|--------|
| SELECT 列 | df[["列"]] |
| WHERE | df[df["列"] > 值] |
| GROUP BY + 聚合 | df.groupby("列").agg(...) |
| ORDER BY | df.sort_values("列") |
| JOIN | pd.merge(df1, df2, on="键", how=...) |
| UNION ALL | pd.concat([df1, df2]) |
| LIMIT | df.head(n) / df.iloc[:n] |

---

## 今日面试考点清单
1. 分组多聚合？→ groupby().agg(["count","sum",...]) 或 (列,函数) 元组
2. merge 的 how？→ inner/left/right/outer ↔ JOIN
3. left join 缺失？→ 右表列 NaN
4. concat？→ 纵向拼 = UNION ALL
5. Pandas↔SQL？→ WHERE/ORDER BY/LIMIT 等对应写法

## 踩坑记录（面试素材）
- groupby 结果索引是分组键 → reset_index() 转回普通列
- concat 不 ignore_index → 索引重复
- merge 忘指定 on → 报错或按共同列自动匹配
- left join 以为一定包含右表全部 → 以左表为准
- agg 列名重名 → 元组命名避免覆盖
