#!/bin/bash
# Day18 演示：Linux 巡检脚本（磁盘/内存/负载采集 + 阈值告警 + 日志输出）
# 用法：sudo ./check.sh   （/var/log 写入需要 root）
# 定时调度：crontab -e 添加  */5 * * * * /home/vboxuser/check.sh

set -euo pipefail

{
date +"%Y-%m-%d %H:%M:%S"
df -h | grep " /$"
free -h | grep Mem
uptime
ss -tlnp
who

disk_used=$(df -h | grep " /$" | awk '{print $5}' | sed 's/%//')
if [ $disk_used -gt 80 ];then
echo "WARNING: 根分区磁盘使用率过高！"
else
echo "INFO: 磁盘使用率正常"
fi

available=$(free | grep Mem | awk '{print $7}')
if [ $available -lt 1024 ];then
echo "WARNING: 内存不足！"
else
echo "INFO: 内存充足"
fi

load=$(uptime | awk '{print $(NF-2)}')
if [ $(echo "$load > 1.0" | bc) -eq 1 ];then
echo "WARNING: 系统负载过高！"
else
echo "INFO: 系统负载正常"
fi

echo "======="
} | tee -a /var/log/check.log
