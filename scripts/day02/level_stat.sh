#!/bin/bash
if [ $# -ne 1 ];then
  echo "用法：./level_stat.sh [日志级别]"
  exit 1
fi
level=$1
if [ $level == "error" ] || [ $level == "warn" ];then
  count=$(grep $level test.log | wc -l)
  echo "test.log中关键词${level}的总行数是：$count"
else
  echo "不支持的日志级别"
fi
