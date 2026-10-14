-- ============================================================
-- Day50：ADS 报表 SQL（DWS → ADS，虚拟机实测通过）
-- 口径：GMV = 已支付金额合计；客单价 = GMV/订单量
-- 幂等：TRUNCATE 后重算
-- ============================================================

USE dw_project;

-- 清空后重算（幂等）
TRUNCATE ads_gmv_report;

-- 每日 GMV 报表：从 DWS 用户日汇总聚合
INSERT INTO ads_gmv_report (stat_date, gmv, order_cnt, avg_amount)
SELECT stat_date,
       SUM(total_amount) AS gmv,
       SUM(order_cnt)    AS order_cnt,
       ROUND(SUM(total_amount) / SUM(order_cnt), 2) AS avg_amount
FROM dws_user_daily
GROUP BY stat_date;

-- 验证
-- SELECT * FROM ads_gmv_report ORDER BY stat_date;
-- 预期：
-- 2026-10-10 | 3117.00 | 2 | 1558.50
-- 2026-10-11 | 6398.00 | 2 | 3199.00
-- 2026-10-12 |   59.00 | 1 |   59.00
-- 2026-10-13 |  399.00 | 1 |  399.00
