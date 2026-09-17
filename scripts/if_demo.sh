#!/bin/bash
if [ $1 == "error" ];then
  echo "匹配到error日志"
elif [ $1 == "warn" ];then
  echo "匹配到warn日志"
else
  echo "未知日志级别"
fi
