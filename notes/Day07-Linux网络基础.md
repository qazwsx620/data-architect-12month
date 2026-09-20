# Day07 · Linux 网络基础（ip addr / route / DNS / ss / TCP / 防火墙）

> 阶段01 · 第1月 第2周 | 配套脚本见 `scripts/day07/` 目录，虚拟机实测通过。
> 背景：网络排障是运维日常最高频场景，从网卡、路由、DNS、端口、TCP状态到防火墙，面试常考整套排查链路。

---

## 1. 网卡与 IP 查看

```bash
ip addr        # iproute2，系统自带，面试优先记这个
ifconfig       # net-tools，新版 Ubuntu 默认不预装
```
输出重点：
- `lo`：本地回环网卡，127.0.0.1，仅本机内部访问；**不是物理网卡**，拔网线也在
- `enp0s3`：物理网卡，`state UP` 代表网卡启用；`inet 10.0.2.15/24` 是本机 IPv4 地址

> ⚠️【易混淆坑】`UP` 只代表网卡硬件通电就绪，**UP ≠ 已配置 IP**，IP 可单独配置。
> ⚠️【易混淆坑】网卡 `DOWN` = 网卡关闭，与没配 IP 是两回事。

## 2. 路由查看

```bash
ip route
```
| 路由条目 | 含义 |
|----------|------|
| `default via 10.0.2.2 dev enp0s3` | 默认路由（网关）：访问非本地网段 IP 时，数据包交给网关转发 |
| `10.0.2.0/24 dev enp0s3` | 本地直连网段：目标在本网段时二层直达，不经过网关 |
| `169.254.0.0/16` | APIPA 自动私有地址：DHCP 获取 IP 失败时自动分配，不能上网 |

> ✅【面试高频】服务器出现 `169.254` 开头 IP → 优先排查 DHCP 服务。
> metric：路由优先级，数值越小优先级越高。

## 3. 连通性测试与排查顺序

```bash
ping 10.0.2.2      # 测网关
ping 8.8.8.8       # 测公网
ping baidu.com     # 测 DNS 解析
```
> ✅【面试高频】网络排查顺序：**本机 IP → 网关 → 公网 IP → 域名解析**，不要一上来就 ping 域名。
> ⚠️【易混淆坑】ping 8.8.8.8 通、ping baidu.com 不通 → **DNS 解析故障**，不是网络不通。

## 4. DNS 配置

```bash
cat /etc/resolv.conf
resolvectl status   # 查看真实上游 DNS
```
> ⚠️【易混淆坑】Ubuntu systemd-resolved 环境，`/etc/resolv.conf` 是软链接指向 `/run/systemd/resolve/stub-resolv.conf`，**直接编辑重启即失效**。
> ⚠️【易混淆坑】`127.0.0.53` 是本机 systemd-resolved 本地 DNS 代理，不是真正的上游 DNS。

永久配置 DNS（Ubuntu 20.04+ 用 Netplan）：
```yaml
# /etc/netplan/xx.yaml
network:
  ethernets:
    enp0s3:
      nameservers:
        addresses: [223.5.5.5, 8.8.8.8]
```
```bash
sudo netplan apply   # 热加载，不用重启网卡/服务器
```
> ⚠️【易混淆坑】yaml 缩进必须用空格不能用 tab；apply 失败不会自动回滚，修改前先备份。

## 5. 端口查看 ss

```bash
ss -tulnp    # -t TCP -u UDP -l 监听 -n 数字 -p 进程
```
- `0.0.0.0:22`：监听**所有网卡**，外部机器可访问
- `127.0.0.1:631`：**仅本机内部访问**，外部连不上
> ⚠️【易混淆坑】应用配置只监听 127.0.0.1，本地测试正常、远程访问失败，排查端口先看监听地址。

## 6. TCP 三次握手 / 四次挥手（面试必考）

**三次握手（建立连接）**：客户端 SYN → 服务端 SYN+ACK → 客户端 ACK
一句话：确认双方收发能力都正常。

**四次挥手（断开连接）**：客户端 FIN → 服务端 ACK → 服务端 FIN → 客户端 ACK
> ⚠️【易混淆坑】为什么挥手 4 次：服务端收到 FIN 时可能还有剩余数据要发，ACK 和 FIN 不能合并。

**TCP 常见状态**：
| 状态 | 含义 |
|------|------|
| LISTEN | 服务端监听端口，等待连接 |
| ESTABLISHED | 连接已建立，正在通信 |
| TIME_WAIT | 主动关闭一方等待残留报文消失 |
| CLOSE_WAIT | 被动关闭一方，收到 FIN 等待程序 close socket |

> ⚠️【易混淆坑】大量 `CLOSE_WAIT` = 服务端程序没有 close socket，**代码 bug 信号**，生产事故常见。

## 7. tcpdump 抓包

```bash
sudo tcpdump -i lo port 22     # 抓 lo 网卡 22 端口
```
> ⚠️【易混淆坑】本机 ssh 本机，数据包走 **lo 回环网卡**，不经过物理网卡，抓包必须指定 `-i lo`，否则 0 packets captured。

## 8. ufw 防火墙

```bash
sudo ufw status          # 查看状态（不活动=未开启）
sudo ufw allow 22/tcp    # 放行 22 端口
sudo ufw deny from 10.0.2.5   # 拒绝单个 IP
sudo ufw enable          # 开启防火墙
```
> ✅【面试高频】ufw 开启后**默认拒绝入站、允许出站**；开启前务必先放行 ssh，否则远程连接直接断开。
> ⚠️【易混淆坑】防火墙不活动 ≠ 无防火墙；云服务器还有**安全组**要放行。

## 9. 网络排查工具汇总

| 工具 | 用途 |
|------|------|
| ping | ICMP 连通性测试 |
| mtr | 追踪路径，持续统计每一跳延迟/丢包 |
| telnet / nc | 端口连通性测试 |
| ss | 查看 TCP/UDP 连接与端口 |
| tcpdump | 抓包分析报文 |

> ⚠️【易混淆坑】ping 不通 ≠ 端口不能访问：ping 用 ICMP 协议，防火墙可只禁 ICMP 放行业务端口；判断端口可用性用 telnet/nc。

### 外部无法访问 22 端口排查顺序（面试必背）
1. 网卡状态与 IP：`ip addr`
2. 路由/网关：`ip route`
3. 端口监听：`ss -tulnp`，确认监听 0.0.0.0 不是 127.0.0.1
4. 本机自测：`nc -zv 127.0.0.1 22`
5. 防火墙：`ufw status`
6. 客户端连通：ping 服务器 IP、telnet 服务器 IP 22
7. 云服务器/虚拟机额外检查：安全组、端口转发、网络模式

---

## 今日面试考点清单
1. ip addr 中 state UP 代表什么？UP 一定有 IP 吗？→ 网卡通电就绪；UP ≠ 有 IP
2. 默认路由的作用？→ 访问非本地网段时数据包交给网关转发
3. ping 8.8.8.8 通、ping baidu.com 不通？→ DNS 解析故障
4. 0.0.0.0:22 与 127.0.0.1:22 区别？→ 监听所有网卡 vs 仅本机
5. TCP 为什么挥手 4 次？→ 服务端可能还有数据要发，ACK 与 FIN 不能合并
6. TIME_WAIT 是谁的状态？作用？→ 主动关闭方；保证最后 ACK 送达 + 等残留报文消失
7. 外部无法访问 22 端口排查步骤？→ 网卡→路由→端口→自测→防火墙→客户端→安全组/转发
8. 大量 CLOSE_WAIT 代表什么？→ 程序未 close socket，代码 bug
9. 本机 ssh 本机抓包为什么用 -i lo？→ 回环流量不经过物理网卡

## 踩坑记录（面试素材）
- 网卡 UP 当成就绪可访问 → UP 只是硬件就绪，IP 要单独配
- ping 不通就断定防火墙拦截 → ICMP 与业务端口是两回事，用 telnet/nc 测端口
- 直接编辑 /etc/resolv.conf → systemd-resolved 软链接，重启失效；用 netplan
- netplan yaml 用 tab 缩进 → apply 直接报错；必须空格
- 本机抓包指定物理网卡 → 0 packets；回环流量走 lo
- 服务监听 127.0.0.1 远程连不上 → 排查监听地址是否为 0.0.0.0
- ufw enable 前没放行 ssh → 远程连接断开；先 allow 再 enable
- 大量 CLOSE_WAIT 当成网络问题 → 实际是程序没释放连接，代码层排查
