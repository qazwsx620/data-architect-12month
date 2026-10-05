#!/bin/bash
# Day30 演示：主从复制与分库分表相关配置查询
# 用法：mysql -uroot -p 登录后执行
# 说明：完整双实例主从搭建资源较重，本脚本查询单机复制相关配置加深理解

-- 1. binlog 状态（复制数据源）
SHOW VARIABLES LIKE 'log_bin';
SHOW MASTER STATUS;

-- 2. 复制相关配置
SHOW VARIABLES LIKE 'server_id';      -- 每个实例唯一
SHOW VARIABLES LIKE 'binlog_format';  -- ROW 行格式最常用

-- 3. 查看所有二进制日志文件
SHOW BINARY LOGS;

-- 4. 查看从库状态（无从库时为空，主从搭建后 Slave_IO_Running/SQL_Running 应为 YES）
SHOW SLAVE STATUS\G
