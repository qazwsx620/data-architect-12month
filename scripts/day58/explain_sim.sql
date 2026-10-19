-- Day58 实操①：explain 解读 + 谓词下推演示（MySQL 模拟 Hive）

USE dw_project;

-- ① 订单 join 用户 + 过滤 + 聚合：解读执行计划（u 表因需取 user_name+group by 走 ALL）
EXPLAIN SELECT u.user_id, u.user_name, SUM(o.amount)
FROM dwd_order_detail o
JOIN dim_user u ON o.user_id = u.user_id
WHERE o.order_date >= '2026-10-12'
GROUP BY u.user_id, u.user_name;

-- ② 谓词下推演示：只 join 主键不取数据行 → u 走 index（覆盖索引）；
--    o 表 filtered=11.11% 说明 where 在 join 前过滤（下推生效）
EXPLAIN SELECT o.order_id, o.amount
FROM dwd_order_detail o
JOIN dim_user u ON o.user_id = u.user_id
WHERE o.amount > 100;
