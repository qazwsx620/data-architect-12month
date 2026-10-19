-- Day57 实操②：窗口函数 TopN + 累加（MySQL 模拟 Hive，语法一致）

USE dw_project;

-- ① 每用户金额 Top2（row_number）
SELECT user_id, order_id, amount, rn
FROM (
  SELECT user_id, order_id, amount,
         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
  FROM dwd_order_detail
) t WHERE rn <= 2
ORDER BY user_id, rn;

-- ② 按日期累计金额（无 partition by = 全局累计到当前行）
SELECT order_date, order_id, amount,
       SUM(amount) OVER (ORDER BY order_date, order_id) AS running_total
FROM dwd_order_detail
ORDER BY order_date, order_id
LIMIT 6;
