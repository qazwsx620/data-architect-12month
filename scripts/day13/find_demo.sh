#!/bin/bash
# Day13 演示：find 文件查找综合演示（名称/类型/大小/时间/逻辑运算/安全删除）
# 用法：bash find_demo.sh
# 背景：磁盘告警定位大文件、清理过期日志的标准姿势

echo "===== 准备测试文件 ====="
mkdir -p /tmp/find_demo && cd /tmp/find_demo
touch a.txt b.log c.txt 2>/dev/null
dd if=/dev/zero of=big.log bs=1M count=2 2>/dev/null
echo "已创建: a.txt b.log c.txt big.log(2M)"

echo
echo "===== 1. 按名称查找 txt 文件 ====="
find /tmp/find_demo -name "*.txt"

echo
echo "===== 2. 按类型查找普通文件 ====="
find /tmp/find_demo -type f

echo
echo "===== 3. 按大小查找大于 1M 的文件 ====="
find /tmp/find_demo -type f -size +1M

echo
echo "===== 4. 逻辑运算：txt 或 log 文件 ====="
find /tmp/find_demo -type f \( -name "*.txt" -o -name "*.log" \)

echo
echo "===== 5. 安全删除演示（先预览再删）====="
echo "预览将删除的文件："
find /tmp/find_demo -name "*.txt"
echo "确认无误后执行删除："
find /tmp/find_demo -name "*.txt" -delete
echo "剩余文件："
ls /tmp/find_demo

echo
echo "===== 6. 清理测试目录 ====="
rm -rf /tmp/find_demo
echo "已清理"
