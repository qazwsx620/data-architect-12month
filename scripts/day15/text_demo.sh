#!/bin/bash
# Day15 演示：文本处理与重定向综合（sort/uniq/wc/tr/tee/管道 TopN）
# 用法：bash text_demo.sh

echo "===== 1. 生成测试数据 ====="
mkdir -p /tmp/text_demo && cd /tmp/text_demo
cat > app.log << 'EOF'
error 500
error 404
error 500
error 500
error 502
error 404
EOF
cat app.log

echo
echo "===== 2. 错误码 Top 统计（排序+去重+降序）====="
sort app.log | uniq -c | sort -rn

echo
echo "===== 3. tee 双输出：屏幕 + 落盘 ====="
sort app.log | uniq -c | sort -rn | tee result.txt
echo "--- result.txt 内容 ---"
cat result.txt

echo
echo "===== 4. wc 统计 ====="
wc -l app.log

echo
echo "===== 5. tr 删除回车符（Windows 转 Linux）====="
printf 'line1\r\nline2\r\n' > win.txt
tr -d '\r' < win.txt > lin.txt
cat -A lin.txt   # -A 显示行尾符号，验证 \r 已删除

echo
echo "===== 6. 重定向顺序坑对比 ====="
ls /nonexist 2>&1 > a.txt ; echo "a.txt 内容(2>&1 在前): [$(cat a.txt)]"
ls /nonexist > b.txt 2>&1 ; echo "b.txt 内容(> 在前): [$(cat b.txt)]"

echo
echo "===== 7. 清理 ====="
cd / && rm -rf /tmp/text_demo
echo "已清理"
