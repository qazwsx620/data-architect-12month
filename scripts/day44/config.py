# ===== config.py：配置层（改环境只改这里，不动业务代码）=====
INPUT_FILE = "input/orders.csv"

DB_CONFIG = {
    "host": "127.0.0.1",
    "user": "root",
    "password": "123456",
    "database": "test_db",
    "charset": "utf8mb4",
}

# 建表 SQL 常量备用
CREATE_ETL_ORDERS = """
CREATE TABLE IF NOT EXISTS etl_orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1,
    create_date DATE NOT NULL,
    etl_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
"""
