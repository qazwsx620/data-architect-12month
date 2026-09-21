# Day08 · Linux 性能调优（top / free / vmstat / iostat）

> 阶段01 · 第1月 第2周 | 配套脚本见 `scripts/day08/` 目录，虚拟机实测通过。
> 背景：服务器变慢时先分清瓶颈在 CPU、内存还是磁盘 IO，再对症下药；本章是性能排查四板斧。

---

## 1. top —— CPU 与进程实时监控

```bash
top                     # 实时刷新
top -bn1                # 非交互，输出一次快照（脚本中用）
```
关键字段：
- `load average: 0.01, 0.05, 0.08`：系统负载，1/5/15 分钟平均值
- `%Cpu(s)`：us 用户态、sy 内核态、ni nice、id 空闲、wa IO 等待、hi/si 硬/软中断、st 被虚拟化偷走
- `%MEM`：进程内存占比
- 交互键：`P` 按 CPU 排序、`M` 按内存排序、`q` 退出

> ✅【面试高频】load average 与 CPU 核数对比：≈核数 = CPU 满载；远超核数 = CPU 过载、任务排队。
> ⚠️【易混淆坑】load 高 ≠ CPU 瓶颈：等待 IO 的进程也计入负载，wa 高时负载高但 CPU 空闲。

## 2. free —— 内存查看

```bash
free -h
```
| 字段 | 含义 |
|------|------|
| total | 总内存 |
| used | 已用 |
| free | 完全空闲 |
| buff/cache | 磁盘缓冲区+页缓存（可回收） |
| available | **真正可用内存（面试重点）** |

> ⚠️【易混淆坑】used 高不代表内存不够：buff/cache 是 Linux 文件缓存，内存紧张时自动回收；判断内存是否够用看 **available**。
> ✅【面试高频】内存不足触发 **OOM killer**，内核杀掉占用最高进程，报错在 dmesg 查。

### buff/cache 与手动清理
- buffer：块设备（磁盘）写缓冲
- cache：文件读取页缓存
- 生产不建议手动清理：清完缓存磁盘 IO 瞬间飙升，业务变慢（应急可 `sudo sysctl -w vm.drop_caches=3`）

## 3. vmstat —— 全局状态（CPU/内存/IO 一把梭）

```bash
vmstat 1 5     # 每 1 秒输出一次，共 5 次
```
重点字段：
- `si/so`：swap 换入/换出。**持续 > 0 = 物理内存不足，频繁磁盘交换，性能暴跌**
- `bi/bo`：块设备读/写
- `cs`：上下文切换，持续很高 = 大量线程频繁切换，CPU 开销大
- `us/sy/id/wa`：与 top 含义一致

> ✅【面试高频】wa 高、id 高：CPU 不是忙计算，是进程在等磁盘 IO，任务卡住，瓶颈在磁盘。

## 4. iostat —— 磁盘 IO 专项排查

```bash
sudo apt install sysstat -y
iostat -x 1 5     # -x 扩展详情，生产排查必用
```
重点字段（面试背诵）：
| 字段 | 含义 |
|------|------|
| %util | 磁盘利用率；接近 100% = 磁盘饱和 |
| await | IO 平均等待总耗时（应用视角） |
| svctm | 磁盘硬件本身处理 IO 的时间 |
| aqu-sz | IO 平均队列长度 |

> ✅【面试高频】`await = svctm + 排队等待时间`
> - await 远大于 svctm：IO 请求排队积压，IO 瓶颈
> - await ≈ svctm：几乎没有排队，磁盘负载轻
> ⚠️【易混淆坑】SSD 场景 %util 参考价值低，优先看 await 和 aqu-sz。

## 5. 性能排查思路（面试背诵）
1. `top` 看 CPU/负载：us 高 → CPU 密集；wa 高 → 磁盘 IO
2. `free -h` 看内存：available 低 → 内存不足
3. `vmstat` 看全局：si/so > 0 → 内存不足频繁 swap
4. `iostat -x` 看磁盘：await >> svctm、%util 高 → IO 瓶颈

---

## 今日面试考点清单
1. load average 等于 CPU 核数代表什么？→ CPU 满载；大于核数 CPU 过载排队
2. available 和 free 区别？→ free 完全空闲；available = 可立刻回收分配（含可回收 cache），排查看 available
3. wa 高但 idle 高说明什么？→ 瓶颈在磁盘 IO，进程等磁盘，CPU 空闲
4. await 和 svctm 区别？→ await = svctm + 排队时间；await 远大于是 IO 排队瓶颈
5. si/so 持续不为 0 代表什么？→ 内存不足，频繁 swap，性能暴跌
6. buff/cache 是什么？→ buffer 磁盘写缓冲、cache 文件读缓存，可回收，生产不建议手动清理
7. OOM 报错在哪查？→ dmesg / journalctl -k

## 踩坑记录（面试素材）
- load 高就当 CPU 瓶颈 → wa 高时等待 IO 也计入负载，先看 us/wa 区分
- free 看 used 高就以为内存不足 → 看 available；buff/cache 可回收
- 生产随手清 cache → 磁盘 IO 飙升业务变慢；应急才用 drop_caches
- SSD 只看 %util → 参考价值低，看 await/aqu-sz
- 忘了 iostat 需要装 sysstat → Ubuntu 默认没有，先 apt install sysstat
