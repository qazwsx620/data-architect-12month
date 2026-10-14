# Day49 · 数仓项目·DWS 层 ETL：主题汇总（轻度汇总 + 口径一致）

> 模块四 · 数仓工程 Day6 | 配套脚本见 `scripts/day49/dws_aggregate.sql`（虚拟机实测通过）。
> 背景：订单数仓第三层——DWD 明细按主题轻度汇总，ADS 取数无需扫明细。

---

## 1. DWS 定位（面试必答）

**DWS = 按主题做"轻度汇总"的公共层**。把 DWD 明细按常用维度预聚合，ADS 直接取数。

> 为什么叫"轻度"？——只做常规常用维度预聚合（用户-日/商品-日），不做业务专属重汇总（那是 ADS）。

## 2. 汇总主题设计

| 主题 | 表 | 粒度 | 指标 |
|------|-----|------|------|
| 用户主题 | dws_user_daily | 用户-日 | 订单数、总金额 |
| 商品主题 | dws_product_daily | 商品-日 | 订单数、总金额 |

## 3. 口径一致性（重点）

**DWS 汇总必须与 DWD/业务口径对齐**：
- 订单有未支付/已支付/已取消三种状态
- 业务口径：**GMV = 已支付（status=2 / status_name='已支付'）**
- DWS 若全算 → 与 ADS/业务数字对不上

> 面试：口径不一致是数仓最大坑；统一"GMV=已支付"写进文档。

## 4. 汇总 SQL（幂等重算）

```sql
-- 清空后重算（幂等：重复执行结果一致）
TRUNCATE dws_user_daily;
TRUNCATE dws_product_daily;

-- 用户-日汇总：只算已支付（GMV口径）
INSERT INTO dws_user_daily (user_id, stat_date, order_cnt, total_amount)
SELECT user_id, order_date AS stat_date,
       COUNT(*) AS order_cnt,
       SUM(amount) AS total_amount
FROM dwd_order_detail
WHERE status_name = '已支付'
GROUP BY user_id, order_date;

-- 商品-日汇总：只算已支付
INSERT INTO dws_product_daily (product_id, stat_date, order_cnt, total_amount)
SELECT product_id, order_date AS stat_date,
       COUNT(*) AS order_cnt,
       SUM(amount) AS total_amount
FROM dwd_order_detail
WHERE status_name = '已支付'
GROUP BY product_id, order_date;
```

## 5. 运行验证结果

| 表 | 结果 |
|----|------|
| dws_user_daily | 6 行（6 个已支付订单，按用户-日聚合）✅ |
| dws_product_daily | 6 行（6 个已支付订单，按商品-日聚合）✅ |
| 排除项 | 未支付 30002/30007、已取消 30006 正确排除 ✅ |
| 预判核对 | 1001 在 10-10=1单/2999；2001 在 10-10=1单/2999 ✅ |

---

## 今日面试考点清单
1. DWS 轻度汇总？→ 常规维度预聚合，不过度
2. DWS 与 DWD 关系？→ DWD 清洗后按主题汇总
3. GMV 口径？→ 只算已支付，全算数字对不上
4. 幂等重算？→ TRUNCATE 再插入
5. 商品主题粒度？→ 商品-日，回答每日每商品卖多少单/金额（不含订单编号）

## 踩坑记录（面试素材）
- status 数值记混：1=未支付、2=已支付、3=已取消（GMV 用 2）
- 汇总全算 → 口径不一致，数字对不上
- 不 TRUNCATE 重跑 → 数据翻倍
- 商品主题塞订单编号 → 粒度混乱（订单编号是明细层的事）
