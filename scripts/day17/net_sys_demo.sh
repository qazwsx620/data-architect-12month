#!/bin/bash
# Day17 演示：网络工具与系统信息采集（curl/wget/date/uptime/nc/uname）
# 用法：bash net_sys_demo.sh

echo "===== 1. curl 健康检查（-I 只取响应头）====="
curl -I -m 5 http://example.com 2>&1 | head -5

echo
echo "===== 2. wget 下载（-O 自定义文件名）====="
wget -q http://example.com/index.html -O /tmp/example_page.html
ls -lh /tmp/example_page.html

echo
echo "===== 3. date 时间格式化 ====="
date +%Y-%m-%d
date +%H:%M:%S
echo "日志文件名示例: log_$(date +%Y-%m-%d_%H%M%S).log"

echo
echo "===== 4. 系统信息 ====="
echo "内核版本: $(uname -r)"
echo "主机名: $(hostname)"
echo "当前用户: $(whoami)"

echo
echo "===== 5. 负载与登录用户 ====="
uptime
who

echo
echo "===== 6. nc 端口探测（example.com:80）====="
nc -zv example.com 80 2>&1 || echo "nc 未安装或端口不通（sudo apt install netcat）"

echo
echo "===== 7. 清理 ====="
rm -f /tmp/example_page.html
echo "已清理"
