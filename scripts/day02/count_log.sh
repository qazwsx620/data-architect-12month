#!/bin/bash
log_file="test.log"
#统计error数量
error_count=$(grep "error" $log_file | wc -l)
echo "日志文件 ${log_file} 中 error 的总行数：$error_count"
