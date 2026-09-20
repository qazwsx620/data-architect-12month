#!/bin/bash
# Day07 演示：网络状态一键排查脚本（网卡 -> 路由 -> 端口 -> 防火墙）
# 用法：bash net_check.sh
# 背景：外部访问服务器端口不通时，按从底层到上层的顺序排查

echo "===== 1. 网卡状态与 IP（ip addr）====="
ip addr | grep -E "^[0-9]+:|inet " | grep -v "inet6"

echo
echo "===== 2. 路由与默认网关（ip route）====="
ip route

echo
echo "===== 3. 端口监听（ss -tulnp）====="
ss -tulnp

echo
echo "===== 4. 常见服务端口本地自测 ====="
for port in 22 80 443; do
  if timeout 2 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null; then
    echo "端口 $port：开放"
  else
    echo "端口 $port：未开放或未监听"
  fi
done

echo
echo "===== 5. ufw 防火墙状态 ====="
sudo ufw status 2>/dev/null || echo "ufw 未安装或无法读取"

echo
echo "===== 6. 排查提示 ====="
echo "外部访问不通顺序：网卡 -> 路由 -> 端口监听 -> 本机自测 -> 防火墙 -> 客户端连通 -> 安全组/端口转发"
