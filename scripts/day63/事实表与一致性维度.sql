-- Day63 实操：事实表分类识别 + 退化维度 + 一致性维度验证

USE dw_project;

-- ===== 实操②：退化维度识别（模块四 fact_order） =====
DESC fact_order;
-- order_id: PRI（业务主键，退化维度，无维度表）
-- user_id / product_id: 外键维度（关联 dim_user / dim_product）

SELECT COUNT(*) AS 总单数, COUNT(DISTINCT order_id) AS 不重复单号 FROM fact_order;

-- ===== 实操③：一致性维度验证 =====
-- ① 维度表现状检查（坑：空表会导致 join 全 NULL）
SELECT * FROM dim_user;
SELECT * FROM dim_product;

-- ② 灌入维度数据
INSERT INTO dim_user (user_id, user_name) VALUES
  (1001,'张三丰'),(1002,'李四'),(1003,'王五'),(1004,'赵六'),(1005,'钱七'),
  (1006,'孙八'),(1007,'周九');
INSERT INTO dim_product (product_id, product_name) VALUES
  (2001,'手机'),(2002,'笔记本'),(2003,'耳机'),(2004,'键盘'),(2005,'鼠标');

-- ③ 用户维一致性：dws_user_daily 通过同一套 dim_user 关联
SELECT u.user_name, SUM(d.total_amount) AS 用户总金额
FROM dws_user_daily d
LEFT JOIN dim_user u ON d.user_id = u.user_id
GROUP BY u.user_name ORDER BY 用户总金额 DESC;

-- ④ 商品维一致性：dws_product_daily 通过同一套 dim_product 关联
SELECT p.product_name, SUM(d.total_amount) AS 商品总金额
FROM dws_product_daily d
LEFT JOIN dim_product p ON d.product_id = p.product_id
GROUP BY p.product_name ORDER BY 商品总金额 DESC;

-- ===== 实操①：事务 vs 周期快照设计对比（纸面） =====
-- fact_order（事务）：一行=一单，无周期概念，可加性最强
-- dws_user_daily（周期快照）：一行=用户+一天，周期=天，存储汇总
