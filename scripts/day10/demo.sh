#!/bin/bash
# Day10 演示：systemd 托管的后台守护循环脚本
# 用法：配合 /etc/systemd/system/demo.service 使用
#   [Service]
#   Type=simple
#   User=vboxuser
#   ExecStart=/home/vboxuser/demo.sh
#   Restart=on-failure
#   RestartSec=3
# 验证：kill -9 主 PID 后 systemd 自动拉起新进程

while true
do
    echo "demo service running at $(date)" >> /tmp/demo.log
    sleep 3
done
