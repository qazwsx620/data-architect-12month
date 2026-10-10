# Day42 · ETL 实战项目（CSV 脏数据 → Pandas 清洗 → MySQL → crontab 调度）

> 模块三 · 数仓基础 Day3（压轴实战）| 完整项目见 `scripts/day42/`，虚拟机实测通过。
> 背景：把 Day35-38 Python/Pandas + Day20-31 MySQL 全部串起来，实现生产式 ETL 流程。

---

## 1. ETL 流程（面试口述版）

```
E 抽取：从源头拉数据（本项目：读 CSV）
T 转换：清洗/去重/类型转换/计算（本项目：Pandas）
L 加载：写入目标（本项目：MySQL etl_orders 表）
```

## 2. 项目数据

脏订单 CSV（6 行，含缺失/重复/类型错乱）：
```
order_id,user_id,amount,status,create_date
10001,1001,99.5,1,2026-10-01
10002,1002,abc,2,2026/10/02     ← amount 脏值
10003,1001,199.0,1,2026-10-01
10001,1001,99.5,1,2026-10-01     ← 重复行
10004,1003,299.0,,2026-10-03     ← status 空
10005,1004,,1,2026-10-04         ← amount 空
```

目标表（order_id UNIQUE 保证幂等 + etl_time 记录入库时间）：
```sql
CREATE TABLE IF NOT EXISTS etl_orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1,
    create_date DATE NOT NULL,
    etl_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 3. 清洗顺序（面试高频）

**先类型转换再去重**：去重依赖字段类型一致，`10001` 和 `"10001"` 类型不同会被当成不同行，先去重会失效。

```python
# 1. 类型转换（金额/日期先统一）
df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
df["create_date"] = pd.to_datetime(df["create_date"], format="mixed").dt.strftime("%Y-%m-%d")
# 2. 去重
df = df.drop_duplicates(subset=["order_id"])
# 3. 缺失处理
df["status"] = df["status"].fillna(1).astype(int)
df["amount"] = df["amount"].fillna(0).round(2)
# 4. 校验
df["amount"].isna().sum()
```

## 4. pymysql 写入（💥踩坑）

```python
# 正确：SQL 文本 + 参数分开传
cursor.execute(
    "DELETE FROM etl_orders WHERE order_id IN (%s)" % ",".join(["%s"] * len(df)),
    df["order_id"].tolist()      # 第二参数必须传！
)
cursor.executemany(
    "INSERT INTO etl_orders(order_id, user_id, amount, status, create_date) "
    "VALUES (%s, %s, %s, %s, %s)",
    df[["order_id", "user_id", "amount", "status", "create_date"]].values.tolist()
)
conn.commit()
```

> 💥【坑】execute 不传参数列表 → pymysql 把带 `%s` 的 SQL 原样发给 MySQL → MySQL 不认 `%s` → **1064 语法错误**。占位符必须配合参数传。

## 5. 幂等（重复执行结果一致）

**先删后插**：按 order_id 先 DELETE 已存在数据，再 INSERT。
- 第1次跑：写入5行，总行数5
- 第2次跑：先删后插，总行数**还是5**，不翻倍 ✅

## 6. crontab 定时调度

```bash
crontab -e    # 首次要求选编辑器：输入 1（nano）
```
写入：
```
0 2 * * * cd /home/vboxuser/py_learn/etl_project && /usr/bin/python3 etl.py >> etl.log 2>&1
```
```bash
crontab -l    # 验证
```
> `0 2 * * *` = 每天2:00；`>> etl.log` 日志追加；`2>&1` 错误也进日志。
> 替代写法：`echo "..." | crontab -` 脚本化写入跳过编辑器。

## 7. 数据质量保证（面试必答）

1. **幂等**：重复执行结果一致（先删后插）
2. **校验**：写入后回查行数、金额空值检查
3. **日志**：每次运行写 etl.log 可排查
4. **告警**：行数为0/异常报警（生产用 Airflow/监控）

---

## 今日面试考点清单
1. ETL 三环节？→ 抽取/转换/加载，本项目对应 CSV/Pandas/MySQL
2. 清洗顺序？→ 先类型转换再去重（去重依赖类型一致）
3. pymysql 占位符？→ execute(sql, 参数)，不传参数 1064
4. 幂等？→ 先删后插/唯一键冲突忽略
5. 数据质量？→ 幂等/校验/日志/告警
6. 调度？→ crontab 每天2点 `0 2 * * *`

## 踩坑记录（面试素材）
- execute 忘传参数 → 1064，%s 是 pymysql 占位符
- 先去重后转类型 → 类型不一致去重失效
- 不设 UNIQUE 键 → 重复跑翻倍
- crontab 首次要选编辑器 → 输配置输到 Choose 1-4 上
- 不清除脏值先入库 → 数据质量校验前置
