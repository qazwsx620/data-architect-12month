# Day19 · Linux 故障模拟实战（面试素材：CPU高/inode耗尽/端口冲突/权限/僵尸进程）

> 阶段01 · 第1月 第3周 | 配套脚本见 `scripts/day19/` 目录，虚拟机实测通过。
> 背景：把常见故障亲手制造、复现、定位、解决，形成面试可讲的完整排查案例。

---

## 场景1：死循环拉高 CPU

**制造**：`highcpu.sh` 死循环后台运行
```bash
#!/bin/bash
while true; do :; done
./highcpu.sh &
```

**排查**：
```bash
top            # 按 P 按 CPU 降序，找到 %CPU=100 的进程
ps aux | grep PID
```
**处理**：
```bash
kill PID        # 优雅终止 SIGTERM，优先
kill -9 PID     # 强制 SIGKILL，kill 无效再用
```
> ✅ 面试点：SIGTERM(15) 优雅关闭，进程可收尾清理；SIGKILL(9) 强制杀死无法捕获。优先 kill，无效再 -9。

## 场景2：inode 耗尽

**原理**：inode 数量分区预分配固定；大量极小空文件耗尽 inode → 磁盘有空间但无法新建文件。

**制造**：
```bash
for i in {1..3000}; do touch file_$i.txt; done
```
**排查**：
```bash
df -i          # 看 inode 已用%
find dir -type f | wc -l   # 统计文件数
```
**处理**：删除大量小文件，inode 自动释放。
> ✅ 面试点：磁盘满先 `df -h`，仍报 No space 再 `df -i` 查 inode 耗尽。

## 场景3：端口冲突

**制造**：
```bash
nc -l 8888 &
nc -l 8888     # 报 address already in use
```
**排查**：
```bash
ss -tlnp | grep 8888
lsof -i :8888
```
**处理**：无用进程 kill 释放端口；业务进程改端口或停旧服务。
> ⚠️ 特殊情况：TIME_WAIT 状态端口不能复用，不是进程占用，等自动释放。

## 场景4：权限故障 Permission denied

**原因**：文件缺少 x 执行权限。
**排查/处理**：
```bash
chmod +x script.sh
```
**权限区分（面试高频）**：
- `./script.sh`：作为脚本程序执行，**需要 x 执行权限**
- `bash script.sh`：bash 解释器读取文件，**只需 r 读权限**
- 目录：x 权限=可进入访问；r 权限=可列出文件名

## 场景5：僵尸进程 Zombie

**原理**：子进程退出，父进程存活但未调用 wait/waitpid 回收 → 残留进程表记录，状态 Z，标记 defunct。
**制造**（bash 的 () 子进程常被 shell 自动回收，用 C fork 稳定复现）：
```c
#include <stdio.h>
#include <unistd.h>
int main(){
    pid_t pid = fork();
    if(pid > 0){ printf("父=%d 子=%d\n",getpid(),pid); sleep(20); }
    else if(pid == 0){ return 0; }
    return 0;
}
```
**排查**：
```bash
ps aux | grep defunct     # 状态 Z
ps -ef | grep zombie      # 看 PPID 找父进程
```
**处理**：
```bash
kill 父进程PID   # 僵尸由 init(PID1/systemd) 收养回收
```
> ✅ 面试点：僵尸进程已退出，kill -9 杀不死僵尸本身；只能杀父进程，由 init 回收。

## 附加：孤儿进程 Orphan
父进程先退出，子进程还在运行 → 被 systemd(PID=1) 收养。
> 一句话区分：僵尸=子死父活父不收；孤儿=父死子活 init 收养。

---

## 今日面试考点清单
1. 死循环 CPU 高排查？→ top 按 P 定位，kill（优先）→ kill -9
2. 磁盘有空间但报 No space？→ df -i 查 inode 耗尽
3. address already in use？→ ss/lsof 定位占用端口进程，判断业务处理
4. ./脚本 与 bash 脚本权限？→ 前者要 x，后者要 r
5. 僵尸进程能 kill -9 吗？→ 已退出杀不死，杀父进程由 init 回收
6. 僵尸与孤儿区别？→ 子死父活父不收 vs 父死子活 init 收养
7. kill 与 kill -9 区别？→ SIGTERM 优雅 vs SIGKILL 强制
8. df -h 与 df -i 区别？→ block 空间 vs inode 数量

## 踩坑记录（面试素材）
- bash () 后台子进程被 shell 自动回收，复现僵尸不稳定 → 用 C fork
- 僵尸进程用 kill -9 杀不死 → 子进程已退出，杀父进程由 init 回收
- 磁盘满了只看 df -h → 漏掉 inode 耗尽（df -i）
- 端口 TIME_WAIT 以为进程占用 → TCP 状态，自动释放
- 先 kill -9 直接强杀 → 应优先 kill 优雅终止
