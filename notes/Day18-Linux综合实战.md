# Day18 · Linux 综合实战（巡检脚本 / crontab 调度 / 故障排查流程）

> 阶段01 · 第1月 第3周 | 配套脚本见 `scripts/day18/` 目录，虚拟机实测通过。
> 背景：综合实战课，把 Day01-17 的命令组合成真实可用的巡检脚本；CPU高负载、磁盘上涨排查流程是运维面试大题。

---

## 1. 巡检脚本 check.sh（磁盘/内存/负载 + 告警 + 日志）

```bash
#!/bin/bash
set -euo pipefail
{
date +"%Y-%m-%d %H:%M:%S"
df -h | grep " /$"
free -h | grep Mem
uptime
ss -tlnp
who

disk_used=$(df -h | grep " /$" | awk '{print $5}' | sed 's/%//')
if [ $disk_used -gt 80 ];then
echo "WARNING: 根分区磁盘使用率过高！"
else
echo "INFO: 磁盘使用率正常"
fi

available=$(free | grep Mem | awk '{print $7}')
if [ $available -lt 1024 ];then
echo "WARNING: 内存不足！"
else
echo "INFO: 内存充足"
fi

load=$(uptime | awk '{print $(NF-2)}')
if [ $(echo "$load > 1.0" | bc) -eq 1 ];then
echo "WARNING: 系统负载过高！"
else
echo "INFO: 系统负载正常"
fi

echo "======="
} | tee -a /var/log/check.log
```

### 关键点
- `df -h | grep " /$"`：正则匹配以空格+/结尾的行，精确定位根分区（不误匹配 /dev、/boot 等）
- 磁盘告警：`awk '{print $5}'` 取使用率列 → `sed 's/%//'` 去百分号 → 整数比较
- 内存告警：`free`（不带 -h）输出单位 KB 纯数字，`$7` 是 available 列，<1024 即小于 1G
- 负载告警：`[ ]` 只支持整数，**浮点比较必须用 bc**：`echo "$load > 1.0" | bc`，结果为 1 成立
- `{} | tee -a`：命令组所有输出合并，屏幕 + 追加写日志
- `/var/log/` 写入需 root：`sudo ./check.sh`

### 面试坑点
- `set -e` 下 grep 无匹配会退出脚本 → 生产加 `|| true` 容错
- 负载阈值不应写死 1，应和 CPU 核数对比（4 核阈值 4）
- bc 判断时变量为空会报错 → 生产加非空校验

## 2. crontab 定时调度（每 5 分钟）

```bash
chmod +x /home/vboxuser/check.sh
crontab -e
*/5 * * * * /home/vboxuser/check.sh
```
> ⚠️ 必须**绝对路径**（`/home/...`，不是 `./home/...`）：
> crontab 工作目录不是交互 shell 的目录，环境变量（PATH）简陋，相对路径/自定义命令容易失效。

## 3. 故障排查：CPU 持续高负载

1. `uptime`：看 1/5/15 分钟负载，判断是突发还是持续
2. `top`：按大写 `P` 按 CPU 降序，找占用最高进程 PID
3. `ps aux | grep PID`：看完整启动命令，确认是什么程序
4. `ss -tlnp | grep PID` / `lsof -p PID`：查看进程占用端口/打开的文件
5. 日志定位：systemd 服务用 `journalctl -u 服务名`；普通应用查自身日志文件
6. 加分：`mpstat -P ALL 1` 看每核占用；区分用户态 us 高（业务）vs 内核态 sy 高（内核/IO）

> ⚠️ 坑：`journalctl -u` 跟的是**服务名**，不是 PID。

## 4. 故障排查：磁盘空间持续上涨

1. `df -h`：确认哪个分区满；`df -i`：检查 inode 是否耗尽（inode 满同样无法建文件）
2. 进入高占用目录：`du -sh * | sort -hr` 按大小降序逐层定位
3. 判断大文件类型：日志正常增长还是异常疯狂写入
4. 处理日志：**优先 `> 文件` 清空，不要直接 rm**（进程持有句柄，rm 后空间不释放）
5. 查找已删未释放：`lsof | grep deleted`
6. 清理后 `df -h` 验证回落

> ✅ 高频面试点：rm 删除的只是目录项，进程仍持句柄 → 磁盘空间不释放；`lsof | grep deleted` 定位。

---

## 今日面试考点清单
1. 巡检脚本如何同时屏幕输出+写日志？→ 命令组 {} + tee -a
2. [ ] 能否比较浮点数？→ 不能，整数才可；浮点用 bc
3. crontab 为什么用绝对路径？→ 环境变量简陋、工作目录不同
4. 磁盘满排查顺序？→ df -h + df -i → du -sh * | sort -hr → 定位 → lsof deleted
5. rm 日志后空间不释放原因？→ 进程持有句柄，只删目录项
6. journalctl -u 后面跟什么？→ 服务名，不是 PID
7. top 按 CPU 排序？→ 大写 P
8. 已删除但仍占空间文件怎么查？→ lsof | grep deleted

## 踩坑记录（面试素材）
- 路径写 `./home/...` → 相对路径在 crontab 中失效，必须 `/home/...`
- [ $load -gt 1 ] 遇到小数报错 → 浮点比较用 bc
- df 满了但没查 inode → inode 耗尽同样无法写文件
- rm 大日志空间不释放 → 进程句柄；清空用 > 文件
- journalctl -u 传 PID → -u 是服务名
