-- Day57 实操①：四类内建函数处理订单数据（MySQL 模拟 Hive）
-- 字符串/日期/条件/类型转换

USE dw_project;

SELECT order_id,
       CONCAT('ORD-', order_id)              AS order_code,   -- 字符串拼接
       DATE_FORMAT(order_date, '%Y-%m')      AS month_part,   -- 日期→月份
       DATEDIFF('2026-10-19', order_date)    AS days_ago,     -- 距今天数
       IF(status_name = '已支付', 'PAID', 'NOT_PAID') AS paid_flag, -- 条件分支
       COALESCE(amount, 0)                   AS amount_filled,-- 空值兜底
       CAST(amount AS SIGNED)                AS amount_int    -- 类型转换
FROM dwd_order_detail
LIMIT 5;
