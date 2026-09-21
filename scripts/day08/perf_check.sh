#!/bin/bash
# Day08 演示：服务器性能一键检查脚本（CPU -> 内存 -> 全局 -> 磁盘IO）
# 用法：bash perf_check.sh
# 背景：服务器变慢时按 CPU/内存/IO 顺序快速定位瓶颈

echo "===== 1. CPU 与负载（top 快照）====="
top -bn1 | head -12

echo
echo "===== 2. 内存（free -h）====="
free -h
echo "提示：判断内存是否够用看 available，不是 free；buff/cache 可回收"

echo
echo "===== 3. 全局状态（vmstat 采样 3 次）====="
vmstat 1 3
echo "提示：si/so 持续 > 0 = 内存不足频繁 swap；wa 高 = IO 等待"

echo
echo "===== 4. 磁盘 IO（iostat -x，无 sysstat 则提示安装）====="
if command -v iostat >/dev/null 2>&1; then
  iostat -x 1 3 | grep -E "Device|sda"
else
  echo "iostat 未安装，执行: sudo apt install sysstat -y"
fi
echo "提示：await = svctm + 排队时间；await 远大于是 IO 排队瓶颈；SSD 少看 %util"
