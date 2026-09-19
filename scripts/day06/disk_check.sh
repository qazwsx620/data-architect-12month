#!/bin/bash
# Day06 演示：磁盘占用排查脚本（df 定位分区 -> du 定位大目录）
# 用法：sudo bash disk_check.sh
# 背景：磁盘爆满排障第一步，先看分区占用，再逐级找大文件/大目录

echo "===== 1. 磁盘分区使用率 df -h ====="
df -h

echo
echo "===== 2. /var/log 下各文件占用（日志大户排查） ====="
du -sh /var/log/* 2>/dev/null | sort -rh | head -10

echo
echo "===== 3. 占用最大的前 5 个日志文件 ====="
sudo find /var/log -type f -size +10M -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh | head -5
echo "（无输出表示 /var/log 下没有超过 10M 的文件）"

echo
echo "===== 4. 提示 ====="
echo "若发现超大日志被进程占用，不要直接 rm："
echo "  推荐:  sudo truncate -s 0 /var/log/xxx.log   # 清空文件，空间立即释放"
echo "  已 rm:  重启/重载对应服务释放文件句柄，空间才释放"
