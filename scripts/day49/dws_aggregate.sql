-- ============================================================
-- Day49：DWS 汇总 SQL（DWD → DWS，虚拟机实测通过）
-- 口径：GMV = 已支付（status_name = '已支付'）
-- 幂等：TRUNCATE 后重算
-- ============================================================

USE dw_project;

-- 清空后重算（幂等）
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

-- 验证
-- SELECT * FROM dws_user_daily ORDER BY user_id, stat_date;     -- 6行
-- SELECT * FROM dws_product_daily ORDER BY product_id, stat_date; -- 6行
