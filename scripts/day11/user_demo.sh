#!/bin/bash
# Day11 演示：用户与用户组管理流程（创建 -> 授权 -> 验证 -> 清理）
# 用法：sudo bash user_demo.sh
# 背景：演练新建用户、追加附加组、sudo 授权，最后清理，不污染系统

USER_NAME="demo_user"

echo "===== 1. 创建用户（-m 自动创建家目录+同名主组）====="
sudo useradd -m "$USER_NAME"
echo "创建完成，用户信息："
id "$USER_NAME"

echo
echo "===== 2. 设置密码 ====="
echo "请按提示输入两次密码："
sudo passwd "$USER_NAME"

echo
echo "===== 3. 追加附加组（-aG，保留原组）====="
sudo usermod -aG adm "$USER_NAME"
id "$USER_NAME"
echo "注意：主组 gid 未变，adm 出现在附加组列表"

echo
echo "===== 4. 查看 /etc/passwd 与 /etc/shadow 条目 ====="
grep "$USER_NAME" /etc/passwd
sudo grep "$USER_NAME" /etc/shadow

echo
echo "===== 5. 清理用户（-r 连带家目录）====="
sudo userdel -r "$USER_NAME"
sudo groupdel "$USER_NAME" 2>/dev/null
echo "已删除 $USER_NAME 及其家目录、主组"
