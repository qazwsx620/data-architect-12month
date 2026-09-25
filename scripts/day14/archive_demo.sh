#!/bin/bash
# Day14 演示：压缩归档与软件包管理（tar 打包/解压/查看 + 压缩率对比 + dpkg/apt 常用命令）
# 用法：bash archive_demo.sh

echo "===== 1. 准备测试文件 ====="
mkdir -p /tmp/archive_demo/data
cd /tmp/archive_demo
for i in 1 2 3; do echo "content $i" > data/file$i.txt; done
echo "已创建 3 个测试文件"

echo
echo "===== 2. 三种压缩算法打包对比 ====="
tar -zcf files.tar.gz data
tar -jcf files.tar.bz2 data
tar -Jcf files.tar.xz data
ls -lh files.tar.*

echo
echo "===== 3. 查看包内文件（不解压）====="
tar -ztvf files.tar.gz

echo
echo "===== 4. 解压到指定目录 -C ====="
mkdir -p out
tar -zxvf files.tar.gz -C out
echo "out 目录内容："
ls out

echo
echo "===== 5. 软件包管理常用命令演示 ====="
echo "apt search 示例（仅演示，不实际安装）："
apt search tree 2>/dev/null | head -3 || echo "需要 sudo 或无网络"
echo "提示：实际安装用 sudo apt install 包名；dpkg -i 处理本地 deb 包"

echo
echo "===== 6. 清理测试环境 ====="
cd / && rm -rf /tmp/archive_demo
echo "已清理"
