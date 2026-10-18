-- Day56 实操②：分区裁剪演示（MySQL LIST 分区模拟 Hive 分区）
-- 查 status=2 时 EXPLAIN 的 partitions 列只显示 p_paid → 只扫相关分区

USE test_db;
CREATE TABLE order_part (
  order_id BIGINT, user_id BIGINT, amount DECIMAL(10,2), status TINYINT
)
PARTITION BY LIST (status) (
  PARTITION p_unpaid VALUES IN (1),
  PARTITION p_paid   VALUES IN (2),
  PARTITION p_cancel VALUES IN (3)
);

INSERT INTO order_part VALUES
  (30001,1001,2999.00,2),(30002,1002,99.00,1),(30006,1005,99.00,3);

-- 分区裁剪验证：只扫 p_paid
EXPLAIN SELECT * FROM order_part WHERE status = 2;
