# Day61 · Spark SQL 进阶与优化（Catalyst + 广播/Shuffle JOIN + 窗口函数）

> 模块五 · 大数据数仓进阶 Day6（加量版）| 配套脚本见 `scripts/day61/`。
> 真实环境：Spark 3.5.1 + MySQL 8.0。本日完成 Spark SQL 优化验证 + 模块四 ADS 复现。

---

## 1. Catalyst 优化器（面试必答）

Spark SQL 的**查询优化器**——把 SQL 自动优化后执行：

```text
① 谓词下推：WHERE 过滤提前到读取/join 前（先瘦身再算）
② 列裁剪：只读用到的列，不读整行
③ 常量折叠：WHERE amount > 1+1 自动变 amount > 2
④ 逻辑计划 → 物理计划：自动选最优执行方式
```

### 谓词下推验证（explain 看 PushedFilters）
```scala
spark.sql("""
  SELECT order_date, SUM(amount) AS gmv
  FROM orders WHERE status = 2
  GROUP BY order_date
""").explain()
```
```
Filter (isnotnull(status) AND status = 2)   ← 在聚合之前
FileScan csv ... PushedFilters: [IsNotNull(status), EqualTo(status,2)]
```
过滤下推到 **FileScan 读取时**（PushedFilters）→ 谓词下推生效。

> 加分观察：两个 HashAggregate（partial_sum → sum）+ Exchange = **Spark 自动两阶段聚合**（map 端局部 + reduce 端归并），即 Day58 加盐思想的内置实现。

## 2. 广播 JOIN vs Shuffle JOIN（面试高频）

| | Shuffle JOIN（默认） | 广播 JOIN |
|--|---------------------|-----------|
| 做法 | 两表按 key 哈希跨 Executor 搬运 | 小表复制到每 Executor 内存，大表本地匹配 |
| 代价 | 全表网络搬运（慢） | 小表每节点一份（内存） |
| 关键 | 零 | **零 shuffle** |
| 适用 | 大表 join | 小表（默认 <10MB） |

> 面试一句话：**小表广播、大表 shuffle；广播把 join 从"网络搬运"变成"本地查字典"**。

### 触发
- 自动：`spark.sql.autoBroadcastJoinThreshold`（默认 10MB）
- 手动：`/*+ BROADCAST(小表) */` hint
- 关闭：`spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")`

### 实操②验证
```
默认：BroadcastHashJoin（BuildRight 广播右表 dim_user_small）
关闭后：SortMergeJoin + 两边 Exchange hashpartitioning（Shuffle JOIN）
```

## 3. 窗口函数 + ADS 复现（实操①）

### 窗口函数（Spark/MySQL/Hive 语法一致）
```scala
spark.sql("""
  SELECT user_id, order_id, amount, rn FROM (
    SELECT user_id, order_id, amount,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
    FROM orders
  ) t WHERE rn <= 2 ORDER BY user_id, rn
""").show()
```

### 复现模块四 ADS（gmv/order_cnt/avg_amount，与 MySQL 一致）
```scala
spark.sql("""
  SELECT order_date AS stat_date,
         SUM(CASE WHEN status = 2 THEN amount ELSE 0 END) AS gmv,
         COUNT(CASE WHEN status = 2 THEN 1 END)           AS order_cnt,
         ROUND(SUM(CASE WHEN status = 2 THEN amount ELSE 0 END) /
               COUNT(CASE WHEN status = 2 THEN 1 END), 2) AS avg_amount
  FROM orders
  GROUP BY order_date ORDER BY order_date
""").show()
```
结果：10-10=3117/2/1558.5、10-11=6398/2/3199、10-12=59/1/59 —— 与模块四 ads_gmv_report 完全一致。

---

## 今日面试考点清单
1. Catalyst？→ 优化器：谓词下推/列裁剪/常量折叠
2. 谓词下推怎么验证？→ explain 看 PushedFilters
3. 广播 vs Shuffle JOIN？→ 小表广播零 shuffle；大表只能 shuffle
4. 广播阈值？→ 10MB，conf 可关
5. 两阶段聚合？→ partial_sum+sum = map 端局部+reduce 归并（加盐思想）

## 易混淆坑
- 广播 JOIN 对应"小表"，Shuffle JOIN 是默认（不是"join 适合小表"）
- PushedFilters 出现在 FileScan，说明过滤已下推到读取
- 窗口函数三引擎语法一致（MySQL/Hive/Spark）
- 关闭广播用 -1（不是 0）
