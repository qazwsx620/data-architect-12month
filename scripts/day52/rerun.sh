#!/bin/bash
# Day52 实操④：一键重跑全链路（幂等：重复执行结果一致）
# 用法：./rerun.sh

cd /home/vboxuser/py_learn/etl_project || exit 1
echo "[$(date '+%F %T')] 开始重跑"
python3 etl_chain.py
echo "[$(date '+%F %T')] 重跑结束 exit=$?"
