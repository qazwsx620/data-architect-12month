#!/bin/bash
# Day16 演示：环境变量与 Shell 进阶综合（export/数组/while/函数/case/bash -x）
# 用法：bash env_demo.sh start

echo "===== 1. 普通变量 vs 环境变量 ====="
MY_VAR=hello
echo "子进程看到普通变量: [$(bash -c 'echo $MY_VAR')]"   # 空
export MY_VAR=hello
echo "子进程看到环境变量: [$(bash -c 'echo $MY_VAR')]"   # hello

echo
echo "===== 2. 数组 + for 遍历 ====="
services=(nginx mysql redis)
echo "共 ${#services[@]} 个服务: ${services[@]}"
for s in ${services[@]}; do
    echo "检查: $s"
done

echo
echo "===== 3. while 循环 ====="
i=1
while [ $i -le 3 ]; do
    echo "第 $i 次"
    i=$((i+1))
done

echo
echo "===== 4. 函数 + case 分支 ====="
status() { echo "状态: $1"; }
case $1 in
    start) status running ;;
    stop)  status stopped ;;
    *)     echo "用法: $0 start|stop" ;;
esac

echo
echo "===== 5. 调试提示 ====="
echo "用 bash -x 运行本脚本可逐条查看执行轨迹"
echo "crontab 中找不到命令：用绝对路径或显式设置 PATH"
