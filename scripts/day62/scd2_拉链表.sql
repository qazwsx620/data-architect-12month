-- Day62 实操：SCD2 拉链表全流程（建表 → 装载 → 改名更新 → 时间点快照）

USE dw_project;

-- ===== 实操①：设计 SCD2 表 =====
CREATE TABLE dim_user_scd2 (
  user_id     INT,
  user_name   VARCHAR(50),
  start_date  DATE,          -- 生效日
  end_date    DATE,          -- 失效日（NULL = 当前生效）
  PRIMARY KEY (user_id, start_date)
);

-- 初始装载：10-10 全量快照
INSERT INTO dim_user_scd2 VALUES
  (1001, '张三',  '2026-10-10', NULL),
  (1002, '李四',  '2026-10-10', NULL),
  (1003, '王五',  '2026-10-10', NULL);

-- ===== 实操②：模拟 10-15 用户 1001 改名"张三丰" =====
-- ① 失效旧版本（end_date = 变更前一天）
UPDATE dim_user_scd2
SET end_date = '2026-10-14'
WHERE user_id = 1001 AND end_date IS NULL;

-- ② 插入新版本（10-15 起生效）
INSERT INTO dim_user_scd2 VALUES
  (1001, '张三丰', '2026-10-15', NULL);

-- ③ 10-18 新增用户 1004（新用户直接插入）
INSERT INTO dim_user_scd2 VALUES
  (1004, '赵六', '2026-10-18', NULL);

-- 查看拉链表
SELECT * FROM dim_user_scd2 ORDER BY user_id, start_date;

-- ===== 实操③：时间点快照查询 =====
-- 10-12 快照（应为"张三"）
SELECT user_id, user_name
FROM dim_user_scd2
WHERE start_date <= '2026-10-12'
  AND (end_date IS NULL OR end_date >= '2026-10-12');

-- 10-16 快照（应为"张三丰"）
SELECT user_id, user_name
FROM dim_user_scd2
WHERE start_date <= '2026-10-16'
  AND (end_date IS NULL OR end_date >= '2026-10-16');

-- 当前生效版本
SELECT user_id, user_name FROM dim_user_scd2 WHERE end_date IS NULL;
