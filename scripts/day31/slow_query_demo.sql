#!/bin/bash
# Day31 演示：慢查询日志开启与慢SQL定位
# 用法：mysql -uroot -p 登录后执行
# 收尾：演示完恢复 long_query_time=10，关闭慢日志

-- 1. 查看慢查询配置
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'long_query_time';
SHOW VARIABLES LIKE 'slow_query_log_file';

-- 2. 开启慢查询 + 阈值调0（仅演示，生产勿调0）
SET GLOBAL slow_query_log = ON;
SET GLOBAL long_query_time = 0;

-- 3. 制造慢SQL（SLEEP 3秒，会被记录）
SELECT SLEEP(3);

-- 4. 收尾恢复（生产配置）
SET GLOBAL long_query_time = 10;
SET GLOBAL slow_query_log = OFF;

-- 说明：查看日志在shell执行
-- sudo grep -B 5 "select sleep" /var/lib/mysql/Ubuntu-data-dev-slow.log
