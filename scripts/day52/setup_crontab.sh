# Day52 实操②：crontab 定时调度配置
# 每天 02:00 执行全链路，日志追加

echo "0 2 * * * cd /home/vboxuser/py_learn/etl_project && /usr/bin/python3 etl_chain.py >> /home/vboxuser/py_learn/etl_project/etl_chain.log 2>&1" | crontab -

# 验证
crontab -l
