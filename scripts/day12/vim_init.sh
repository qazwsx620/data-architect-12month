#!/bin/bash
# Day12 演示：vim 练习环境初始化（生成练习文件 + 配置 .vimrc）
# 用法：bash vim_init.sh
# 之后打开练习文件逐个练习三种模式、dd/yy/p、替换、分屏

PRACTICE_FILE=/tmp/vim_practice.txt

echo "===== 1. 生成练习文件 ====="
cat > "$PRACTICE_FILE" << 'EOF'
hello linux
learn vim
data engineer
EOF
echo "已生成 $PRACTICE_FILE"
echo "建议练习：vim $PRACTICE_FILE"
echo "  i 插入 -> Esc 普通 -> :set nu 行号 -> :wq 保存退出"
echo "  yy 复制 / p 粘贴 / dd 删除 / u 撤销 / gg G 首尾行"
echo "  :%s/learn/LEARN/gc 交互式替换"

echo
echo "===== 2. 配置 ~/.vimrc（已存在则追加）====="
touch ~/.vimrc
grep -q "^set nu" ~/.vimrc || echo "set nu" >> ~/.vimrc
grep -q "tabstop" ~/.vimrc || echo "set tabstop=4" >> ~/.vimrc
grep -q "syntax on" ~/.vimrc || echo "syntax on" >> ~/.vimrc
echo "当前 .vimrc 内容："
cat ~/.vimrc

echo
echo "===== 3. 提示 ====="
echo "vim 异常退出会生成 .swp 文件，重新打开提示时 R 恢复 / D 删除"
