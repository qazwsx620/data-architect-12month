-- Day42 ETL 项目初始化：目标表 + 定时调度说明
-- 用法：mysql -uroot -p123456 < etl_init.sql

USE test_db;

-- 目标表：order_id UNIQUE 保证幂等，etl_time 记录入库时间
CREATE TABLE IF NOT EXISTS etl_orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1,
    create_date DATE NOT NULL,
    etl_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

DESC etl_orders;

-- crontab 定时（每天2点，日志追加）：
-- 0 2 * * * cd /home/vboxuser/py_learn/etl_project && /usr/bin/python3 etl.py >> etl.log 2>&1
