# Day17 · 网络工具补充 & 系统信息（curl / wget / uname / date / uptime / nc）

> 阶段01 · 第1月 第3周 | 配套脚本见 `scripts/day17/` 目录，虚拟机实测通过。
> 背景：接口健康检查、文件下载、系统信息采集是日常运维最常用技能；curl 探测服务可用性是面试高频。

---

## 1. curl 网络请求工具

定位：网络请求/接口调试工具，默认发送 GET 请求；**不主打下载文件**（wget 才是）。

### 常用参数
| 参数 | 作用 |
|------|------|
| `-I` | 只获取响应头（HEAD 请求），健康检查首选 |
| `-X POST` | 指定请求方法 |
| `-d` | 携带请求体（POST 传参，配合 -H 可传 JSON） |
| `-H` | 自定义请求头（如 Content-Type） |
| `-m 5` | 设置超时时间，超过 5 秒终止，防脚本卡死 |
| `-o 文件名` | 自定义文件名保存响应内容 |
| `-O` | 自动使用 URL 里的原始文件名保存 |
| `-v` | verbose 详细模式，打印请求/响应/TCP 全过程 |

```bash
curl -I http://example.com                    # 只拿响应头
curl -X POST -d "name=test" http://example.com  # POST 提交
curl -X POST -H "Content-Type:application/json" -d '{"name":"test"}' http://example.com
curl -m 5 -I http://example.com               # 5 秒超时
curl http://example.com -o page.html          # 保存为指定文件
```

### GET vs POST（面试基础）
- GET：参数在 URL 上，用于**查数据**，有长度限制
- POST：参数在**请求体**，用于**提交/新增数据**，无长度限制
- 注意：POST 不等于安全，明文 HTTP 下抓包照样能看到 body；HTTPS 才加密

### 屏幕输出 + 写入文件
curl 本身没有一边打印一边保存的参数，用管道 + tee：
```bash
curl http://example.com | tee result.html
```

## 2. wget 文件下载工具

定位：专门下载文件，支持断点续传、后台下载。

```bash
wget http://example.com/index.html            # 默认保存为 index.html
wget http://example.com/index.html -O my.html # 自定义文件名
wget -c http://example.com/big.tar.gz         # 断点续传（大文件必备）
wget -b http://example.com/index.html         # 后台下载
```

### curl vs wget（面试对比）
- curl：接口测试、发请求、看响应，偏网络调试
- wget：文件下载，自带断点续传，适合拉取大文件

## 3. 系统信息命令

```bash
uname          # 内核名称
uname -r       # 内核版本（面试高频）
uname -a       # 全部信息
hostname       # 主机名
hostnamectl    # 系统版本/内核/架构
uptime         # 开机时长 + load average
last           # 登录历史
whoami         # 当前登录用户
who            # 当前登录用户（精简）
w              # 登录用户 + 负载 + 用户当前进程（信息最全）
```

## 4. date 时间格式化（脚本高频）

```bash
date +%Y-%m-%d            # 2026-09-27
date +%H:%M:%S            # 15:30:00
date +%Y-%m-%d\ %H:%M:%S  # 完整时间戳
```
- `%Y` 4位年 / `%m` 月 / `%d` 日 / `%H` 24小时制小时 / `%M` 分 / `%S` 秒
- 应用：脚本生成带时间戳的日志文件名

## 5. nc 端口探测

```bash
nc -zv example.com 80
```
- `-z`：只扫描端口，不传输数据
- `-v`：打印详细信息
- 面试场景：服务器连不上另一台的端口，优先 nc 测连通
- Ubuntu 默认可能未装：`sudo apt install netcat`

## 6. load average 解读

`load average: 0.32, 0.45, 0.38` = 1分钟、5分钟、15分钟平均负载
- 含义：等待 CPU 运行的任务数
- 单核接近 1 满负荷；多核参考值 = CPU 核心数
- 长期压力看 15 分钟值，突发压力看 1 分钟值

---

## 今日面试考点清单
1. curl 只取响应头参数？→ -I（HEAD 请求）
2. curl 设置超时？→ -m 秒数
3. GET 与 POST 区别？→ 参数位置（URL vs body），读 vs 写
4. curl 屏幕+文件同时输出？→ 管道 tee
5. wget 断点续传？→ -c
6. curl 与 wget 定位？→ 接口调试 vs 文件下载
7. 查看内核版本？→ uname -r
8. date 输出 年-月-日？→ date +%Y-%m-%d
9. nc 测端口连通？→ nc -zv 主机 端口
10. load average 三个数？→ 1/5/15 分钟

## 踩坑记录（面试素材）
- %H 当成年份 → %H 是小时，年份是 %Y
- curl 用 get 获取响应头 → 正确是 -I（HEAD）
- curl 误当下载工具 → 下载用 wget（断点续传）
- 以为 POST 安全 → 明文 HTTP 抓包照样泄露，安全靠 HTTPS
- load 单核 1.0 就满载 → 多核要按核数折算参考值
