-- Day57 实操③：行转列模拟（MySQL 无 explode，用序列表拆逗号串）
-- 对应 Hive: LATERAL VIEW explode(tags) t AS tag

USE test_db;

CREATE TABLE IF NOT EXISTS order_tags (
  order_id BIGINT,
  tags VARCHAR(50)   -- 逗号分隔，模拟 Hive 数组
);
INSERT INTO order_tags VALUES
  (30001, '秒杀,会员'),
  (30002, '新品'),
  (30003, '秒杀,新品,会员');

-- 模拟 explode：逗号拆分成多行（序列表 1..5 逐个提取）
WITH seq AS (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
             UNION ALL SELECT 4 UNION ALL SELECT 5)
SELECT o.order_id,
       SUBSTRING_INDEX(SUBSTRING_INDEX(o.tags, ',', s.n), ',', -1) AS tag
FROM order_tags o
JOIN seq s ON s.n <= (LENGTH(o.tags) - LENGTH(REPLACE(o.tags, ',', '')) + 1)
ORDER BY o.order_id, tag;
