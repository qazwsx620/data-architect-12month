# Day06 · Linux 系统日志 & 系统故障排查（syslog / journalctl / dmesg / logrotate）

> 阶段01 · 第1月 第2周 | 配套脚本见 `scripts/day06/` 目录，虚拟机实测通过。
> 背景：日志是排障、审计、定位报错的核心依据；日志把磁盘打满、SSH被暴力破解、服务莫名挂掉，都靠本章排查。

---

## 1. syslog 日志体系

### 1.1 基础概念
> ✅【面试高频】Linux 有两套日志体系：**syslog 传统文本日志** 与 **systemd-journal 二进制日志**，生产环境通常同时运行。

syslog 是一套日志**标准协议**，传统实现（rsyslog）把日志输出为**文本文件**，存放在 `/var/log/` 目录，可用 `cat/tail/grep` 直接读取。

### 1.2 设施 facility（日志来源分类）
| facility | 含义 |
|----------|------|
| kern | 内核日志 |
| user | 用户进程日志 |
| daemon | 后台守护进程 |
| auth | 认证相关（登录、密码） |
| cron | crontab 定时任务日志 |

> ⚠️【易混淆坑】facility 是**来源分类**，不是日志级别。

### 1.3 日志优先级 priority（从高到低）
```
emerg > alert > crit > err > warn > notice > info > debug
```
> ✅【面试题】生产环境一般不开 debug，日志量巨大占满磁盘。

### 1.4 Ubuntu 文本日志文件位置
| 文件 | 内容 |
|------|------|
| /var/log/syslog | 系统综合日志 |
| /var/log/auth.log | 登录、ssh、sudo 认证日志（安全审计重点） |
| /var/log/cron.log | crontab 定时任务日志 |
| /var/log/dmesg | 内核、硬件日志归档 |

> ⚠️【易混淆坑】`dmesg` 命令读的是**内核环形缓冲区（内存）**，不是直接读 `/var/log/dmesg` 文件；内存里的日志重启会丢失。

## 2. journalctl（systemd 日志，面试高频）

systemd 管理的服务日志存放在二进制 journal 文件中，只能用 journalctl 解析查看。

```bash
journalctl              # 查看全部日志（分页）
journalctl -b           # 本次开机之后的日志
journalctl -f           # 实时滚动，类似 tail -f
journalctl -u ssh       # 指定服务日志（-u unit）
journalctl -k           # 内核日志，等价 dmesg 的持久化版
journalctl -p err       # err 及以上级别（含 crit/alert/emerg）
journalctl --since "yesterday" --until "today"   # 时间范围过滤
```

> ⚠️【易混淆坑】`-p err` 输出 err、crit、alert、emerg **全部更高级别**，不是只输出 err。
> ⚠️【易混淆坑】时间字符串必须加引号；支持 `yesterday` / `today` / `1 hour ago` 写法。

### journal 日志持久化（面试重点）
journal 默认 `Storage=auto`，日志量大才落盘，重启可能丢失部分日志。修改配置 `/etc/systemd/journald.conf`：
```ini
Storage=persistent     # 日志永久保存到 /var/log/journal/，重启不丢
```
```bash
sudo systemctl restart systemd-journald   # 重启服务生效
```
> 其他取值：`volatile` 只存内存（重启全丢）；`none` 不记录。
> ⚠️【易混淆坑】这不是命令行参数能改的，必须改配置文件。

## 3. dmesg 内核日志

内核检测硬件、驱动报错、OOM 内存溢出都会打印到内核环形缓冲区：
```bash
dmesg                 # 查看内核缓冲区日志
dmesg --level=err     # 只看错误级别
dmesg -w              # 实时监控内核日志
```
> ✅【面试重点】**OOM killer（内存溢出杀手）**：系统内存耗尽，内核主动杀掉占用内存最高的进程，日志在 dmesg 里查。

### journalctl -k 与 dmesg 的区别（高频面试题）
| 对比 | dmesg | journalctl -k |
|------|-------|---------------|
| 数据来源 | 内核环形缓冲区（内存） | journald 持久化到磁盘的 journal 文件 |
| 重启后 | 旧日志丢失 | 历史内核日志仍在 |
| 本质 | 直接读内存 | 开机后 journald 抓取缓冲区写入磁盘 |

## 4. logrotate 日志轮转（面试重点）

> ✅【高频】logrotate 不是守护进程，**靠 crontab 定时触发执行**。
> 问题背景：日志持续写入会占满磁盘，logrotate 负责切割、压缩、清理旧日志。

配置位置：
- 主配置：`/etc/logrotate.conf`
- 服务单独配置：`/etc/logrotate.d/`（rsyslog、nginx、ssh 等）

rsyslog 配置示例解读：
```
rotate 4          # 保留最近 4 个归档，超出删除最老的
weekly            # 每周切割一次
missingok         # 日志文件不存在不报错
notifempty        # 文件为空不切割
compress          # 旧日志 gzip 压缩
delaycompress     # 本次切割的文件下一轮才压缩（避免正在写入的文件压缩出错）
sharedscripts     # 所有日志处理完只执行一次 postrotate
postrotate        # 切割后通知服务重新打开日志文件
    /usr/lib/rsyslog/rsyslog-rotate
endscript
```

### 思考题：切割时正在写入的进程怎么办？
logrotate 重命名日志文件后，进程仍持有**旧文件句柄**，会继续往改名后的文件写。两种方案：
1. **postrotate**：发信号让服务重新打开日志文件（rsyslog 方案，推荐）
2. **copytruncate**：先复制一份再清空原文件，适合无法发信号的程序
> ⚠️【坑】copytruncate 复制过程会丢失少量日志，生产优先 postrotate。

## 5. 磁盘爆满排查（实战高频）

排查顺序：
```bash
df -h               # 1. 看哪个分区满了
sudo du -sh /var/log/*   # 2. 定位占用大的目录/文件（经常是日志）
```

> ⚠️【高频坑】磁盘满且进程持续写入大日志，**直接 `rm -f 日志` 不会释放空间**：rm 只删目录条目，进程仍持有文件句柄，内核不释放磁盘块，`df -h` 占用率不变。
> 正确做法：
> 1. `> huge.log` 或 `truncate -s 0 huge.log` 清空文件（推荐，空间立即释放）
> 2. 已 rm 的，需重启/重载对应服务释放句柄，空间才释放

---

## 今日面试考点清单
1. SSH 登录失败，优先查看哪个日志？→ /var/log/auth.log（认证审计）
2. OOM 内核报错用什么命令看？→ dmesg / journalctl -k
3. dmesg 与 journalctl -k 区别？→ 内存环形缓冲区（重启丢失）vs 磁盘持久化 journal（重启还在）
4. logrotate 是守护进程吗？靠什么触发？→ 不是；靠 crontab 定时触发
5. 磁盘满直接 rm 正在写入的日志会释放空间吗？→ 不会；句柄未释放，需清空文件或重启服务
6. journalctl -p err 输出什么级别？→ err 及以上（crit/alert/emerg）
7. journal 日志如何永久保存？→ /etc/systemd/journald.conf 改 Storage=persistent
8. logrotate 切割时如何让进程写新文件？→ postrotate 通知服务重开文件 / copytruncate

## 踩坑记录（面试素材）
- 误以为 /var/log/dmesg 就是 dmesg 数据源 → dmesg 命令读内存环形缓冲区，重启丢失
- journalctl -p err 以为只出 err → 实际包含所有更高级别
- 认为 logrotate 是常驻守护进程 → 靠 crontab 定时触发
- 磁盘满直接 rm 大日志 → 句柄未释放空间不降；先 truncate 清空或重启服务
- 以为命令行参数能永久改 journal 存储 → 必须改 /etc/systemd/journald.conf
- copytruncate 与 postrotate 混淆 → 前者丢日志，生产优先 postrotate
