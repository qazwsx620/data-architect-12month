#!/bin/bash
# Day05 演示：inode 与软硬链接
# 用法：bash link_demo.sh（在 scripts/day05/ 目录内执行）

cd "$(dirname "$0")" || exit 1

echo "hello inode" > origin.txt

ln origin.txt hard.txt      # 硬链接：同一 inode 新增别名
ln -s origin.txt soft.txt   # 软链接：独立文件，内容存路径字符串

echo "===== ls -li 查看 inode 与链接计数 ====="
ls -li origin.txt hard.txt soft.txt

echo
echo "===== 删除源文件 origin.txt ====="
rm origin.txt
ls -li hard.txt soft.txt 2>&1

echo
echo "===== 硬链接仍可读，软链接悬空 ====="
echo "hard.txt 内容: $(cat hard.txt)"
cat soft.txt 2>&1 || echo "soft.txt 悬空（broken link）"

echo
echo "===== 新建同名源文件，软链接自动恢复 ====="
echo "new content" > origin.txt
cat soft.txt

echo
echo "===== 清理演示文件 ====="
rm -f origin.txt hard.txt soft.txt
ls -li
