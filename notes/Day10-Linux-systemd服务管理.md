# Day10 · Linux systemd 服务管理（systemctl / unit / service 文件）

> 阶段01 · 第1月 第2周 | 配套脚本见 `scripts/day10/` 目录，虚拟机实测通过。
> 背景：Ubuntu/CentOS7+ 的现代服务管理全靠 systemd；面试常考 unit、service 文件、开机自启、Restart 策略、服务故障排查。

---

## 1. 基础概念

**systemd**：系统与服务管理器，替代老旧 SysVinit，**并行启动**服务，管理最小单元为 **unit**。

unit 常见类型：
| 后缀 | 含义 |
|------|------|
| .service | 服务单元（最常用，后台程序） |
| .target | 一组 unit 的集合（相当于运行级别） |
| .mount | 文件系统挂载单元 |
| .socket | 套接字单元，支持 socket 激活 |

常用 target：
- `multi-user.target`：多用户无图形（旧 runlevel3）
- `graphical.target`：图形界面（旧 runlevel5）
```bash
systemctl get-default                      # 查看默认启动目标
sudo systemctl set-default multi-user.target  # 修改默认目标
```

## 2. systemctl 核心命令

```bash
systemctl list-units --type=service        # 查看所有服务
sudo systemctl start 服务名                  # 启动
sudo systemctl stop 服务名                   # 停止
sudo systemctl restart 服务名                # 重启（先停再启，中断业务）
sudo systemctl reload 服务名                 # 热重载配置（不杀进程，需程序支持）
sudo systemctl enable 服务名                 # 设置开机自启（不立即启动）
sudo systemctl disable 服务名                # 取消开机自启
systemctl is-enabled 服务名                  # 查看是否开机自启
systemctl status 服务名                      # 查看详细状态（重点看报错）
sudo systemctl enable --now 服务名           # 开机自启 + 立即启动
```
> ⚠️【易混淆坑】`enable` 只配置开机自启，**不会立刻启动服务**；`start` 只当前启动，不配自启。
> ⚠️ reload 与 restart：reload 热重载不中断；restart 先停后启会中断业务。

## 3. service 文件结构

存放路径：
- `/lib/systemd/system/`：系统自带服务
- `/etc/systemd/system/`：**自定义服务（优先读取）**

```ini
[Unit]
Description=Demo Test Service
After=network.target          # 启动顺序：network.target 之后再启动
Wants=network.target          # 弱依赖：网络失败本服务照常启动
# Requires=network.target     # 强依赖：网络失败本服务不启动

[Service]
Type=simple                   # simple/forking/oneshot
User=vboxuser                 # 运行用户
ExecStart=/home/vboxuser/demo.sh   # 启动命令，绝对路径
Restart=on-failure            # 重启策略
RestartSec=3                  # 重启前等待秒数，防重启风暴

[Install]
WantedBy=multi-user.target    # enable 时归属的 target
```
- `[Unit]`：描述、依赖、启动顺序
- `[Service]`：进程本身配置
- `[Install]`：仅 `systemctl enable` 时读取

> ✅【面试高频】After 只控制**启动顺序**，不等于依赖；依赖关系用 Wants（弱）/ Requires（强）。
> ⚠️【易混淆坑】修改 service 文件后必须 `sudo systemctl daemon-reload` 重载配置缓存，否则 restart 读到的还是旧配置。

## 4. Type 类型（面试必考）

| 类型 | 行为 | 适用 |
|------|------|------|
| simple（默认）| ExecStart 拉起的进程就是主进程，前台运行 | 常驻程序、bash 循环脚本、现代应用 |
| forking | 程序 fork 子进程，父进程退出，业务跑子进程 | 老守护进程（旧 nginx/redis） |
| oneshot | 一次性任务，执行完就退出，不需要常驻 | 初始化、一次性清理脚本 |

## 5. Restart 重启策略

| 取值 | 行为 |
|------|------|
| no（默认）| 退出永不重启 |
| on-failure | **仅异常退出才重启**（崩溃、kill -9、非0退出码） |
| on-abnormal | 超时、被 SIGKILL 才重启 |
| always | **无论正常(SIGTERM)还是异常(SIGKILL)退出，一律重启** |

> ✅【实验结论】SIGTERM 属正常退出，on-failure **不重启**；SIGKILL 属异常退出，on-failure **自动重启**。
> ⚠️【易混淆坑】生产慎用 always：脚本持续报错会触发**无限快速重启风暴**，配合 RestartSec 缓解。

## 6. 服务日志查看（联动 Day06）

```bash
journalctl -u 服务名          # 查看指定服务全部日志
journalctl -u 服务名 -f       # 实时滚动
journalctl -u 服务名 -b       # 本次开机以来
```
> 排障顺序：`systemctl status 服务名` 看状态与报错 → `journalctl -u 服务名` 看详细日志。
> 权限提示：加入 adm/systemd-journal 组可查看全部日志（重新登录生效）。

---

## 今日面试考点清单
1. unit 是什么？service 文件两个路径？→ systemd 最小管理单元；/lib/systemd/system（自带）与 /etc/systemd/system（自定义优先）
2. enable 和 start 区别？→ enable 配置开机自启不立即启动；start 立即启动不配自启；enable --now 两者同时
3. After 与 Requires 区别？→ After 只控顺序非依赖；Requires 强依赖，失败则不启动
4. reload 与 restart 区别？→ 热重载不中断 vs 先停后启中断业务
5. Type=simple/forking/oneshot 区别？→ 前台主进程 / fork 子进程 / 一次性任务
6. Restart=on-failure 与 always 区别？→ 仅异常退出重启 vs 任何退出都重启
7. 修改 service 文件后必须做什么？→ daemon-reload 重载配置缓存
8. 服务启动失败排查？→ status 看状态报错 + journalctl -u 看详细日志

## 踩坑记录（面试素材）
- enable 以为会立即启动 → enable 只配自启，需 start 或 enable --now
- After 当成依赖 → After 只控顺序，依赖用 Wants/Requires
- 改 service 文件不 daemon-reload → restart 仍用旧配置，修改不生效
- SIGTERM 被 on-failure 重启 → 正常退出不重启；只有异常退出（kill -9/崩溃）才重启
- always 无 RestartSec → 报错脚本无限重启风暴
- journalctl 权限不足看不了全部日志 → 加 adm/systemd-journal 组
