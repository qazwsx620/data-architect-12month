-- Day64 实操①：information_schema 采集技术元数据

-- 表级元数据
SELECT table_name, table_type, create_time
FROM information_schema.tables
WHERE table_schema = 'dw_project'
ORDER BY table_name;

-- 字段级元数据
SELECT table_name, column_name, data_type, is_nullable, column_key
FROM information_schema.columns
WHERE table_schema = 'dw_project'
ORDER BY table_name, ordinal_position;
