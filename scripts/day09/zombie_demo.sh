#!/bin/bash
# Day09 演示：制造并观察僵尸进程
# 用法：bash zombie_demo.sh  （后台运行后在另一终端 ps -ef | grep defunct 观察 Z 状态）
# 原理：子进程先退出 -> 父进程存活且不调用 wait -> 子进程残留为僵尸(Z)

echo "父进程 PID: $$"

# 子进程：2 秒后退出（后台执行）
(
    echo "子进程 PID: $BASHPID"
    sleep 2
    echo "子进程已退出，进入僵尸状态..."
    exit 0
) &

echo "父进程休眠 10 秒，不调用 wait 回收子进程"
echo "请在新终端执行: ps -ef | grep defunct  观察 Z 僵尸"
sleep 10

echo "父进程睡醒，回收僵尸"
wait
echo "观察 ps -ef | grep defunct，僵尸应已消失"
