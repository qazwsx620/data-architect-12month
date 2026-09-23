# Day11 · Linux 用户与用户组管理（UID/GID / passwd / shadow / su / sudo）

> 阶段01 · 第1月 第2周 | 配套脚本见 `scripts/day11/` 目录，虚拟机实测通过。
> 背景：Linux 是多用户操作系统，一切资源（文件/进程）归属用户+用户组；权限判定依托 UID/GID。

---

## 1. 基础概念

- **UID（User ID）**：内核识别用户的数字编号，不是用户名
  - root：UID=0（超级管理员）
  - 系统内置服务账号：1~999（不能登录，运行服务用，如 www-data）
  - Ubuntu 普通新建用户：从 1000 开始
- **GID（Group ID）**：用户组 ID
- 新建用户默认**自动创建同名私有组**作为主组

> ✅【面试高频】一个用户：**1 个主组 + 多个附加组**。
> - 主组：新建文件时文件的默认归属组
> - 附加组：额外加入的组，用于获取对应组权限

## 2. 三大核心配置文件（必背）

### /etc/passwd —— 用户基本信息，所有用户可读
```
vboxuser:x:1000:1000:vboxuser,,,:/home/vboxuser:/bin/bash
```
7 段（冒号分隔）：`用户名:密码占位符(x):UID:GID:注释信息:家目录:登录shell`
> ⚠️【易混淆坑】`x` 不是密码，只是占位符，代表密码哈希存在 /etc/shadow。

### /etc/shadow —— 加密密码哈希，仅 root 可读
9 段：用户名、密码哈希、最后修改天数、最小间隔、有效期、过期提醒、宽限天数、失效日期、保留字段
- `$6$` 开头：SHA-512 加密（`$y$` 为 yescrypt 新算法）
- `!`：**账号锁定**（passwd -l 锁账号写入 !），禁止密码登录
- `*`：**系统服务账号**，从未设置密码，禁止登录，用于跑后台服务

> ✅【面试高频】`!` 是人为锁定（可 passwd -u 解锁）；`*` 是天生无密码的系统账号，不能用密码登录。

### /etc/group —— 用户组信息
`组名:x:GID:附加用户列表`

## 3. 用户 & 组命令

```bash
sudo useradd -m testuser     # 新建用户，-m 自动创建家目录+同名主组
sudo passwd testuser         # 设置密码
id testuser                  # 查看 UID/GID/全部所属组
sudo usermod -aG adm testuser  # 追加附加组（-a 不能丢）
sudo userdel -r testuser     # 删除用户，-r 连带删除家目录
sudo groupadd testgroup      # 新建组
sudo groupdel testgroup      # 删除组
```
> ⚠️【易混淆坑】`usermod -G` 不带 `-a` 会**覆盖全部附加组导致丢组**；必须用 `-aG` 追加。
> ⚠️ useradd 不加 `-m`：不创建家目录，不生成同名组，默认 shell 是 /bin/sh。

## 4. su 与 sudo（超级高频面试题）

| 对比 | su - 用户名 | sudo 命令 |
|------|-----------|-----------|
| 本质 | 完整切换用户身份（含环境变量） | 临时借用 root 权限执行单条命令 |
| 密码 | 需要**目标用户**密码 | 输入**当前用户自己**密码（NOPASSWD 免密）|
| 权限 | 切换后完全放开 | 执行完回到原身份 |
| 前提 | 知道目标密码 | 当前用户在 sudo 授权列表 |

> 注意：`su` 不带 `-` 只切换身份、环境变量不变；`su -` 加载目标用户完整环境（推荐）。

## 5. sudo 授权配置 /etc/sudoers

编辑命令：**`sudo visudo`**（自带语法校验，写错不会锁死 sudo）
> ⚠️【易混淆坑】禁止直接 vim /etc/sudoers：一旦语法错误，所有 sudo 全部失效无法修复。

配置格式：
```
用户名  主机=(可切换用户:可切换组)  允许命令
```
示例：
```
testuser    ALL=(ALL:ALL) ALL             # 全部主机、可切换任何用户组、执行所有命令
testuser    ALL=(ALL:ALL) NOPASSWD: ALL   # 免密 sudo
```
分段含义：
1. `testuser`：授权用户名
2. 第 1 个 ALL：生效主机（ALL=所有主机）
3. `(ALL:ALL)`：可切换的用户:用户组
4. 最后 ALL：允许执行的命令范围

---

## 今日面试考点清单
1. /etc/passwd 7 段字段？→ 用户名:x:UID:GID:注释:家目录:登录shell（x 是密码占位符）
2. /etc/shadow 里 ! 与 * 区别？→ ! 人为锁定账号；* 系统服务账号从未设密码
3. useradd -m 作用？→ 自动创建家目录+同名主组；不加 m 不创建
4. usermod -aG 与 -G 区别？→ -G 覆盖丢组；-aG 追加保留
5. 一个用户几个主组几个附加组？→ 1 个主组，多个附加组
6. su 与 sudo 区别？→ 完整切换需目标密码 vs 临时借用权限输自己密码
7. 为什么用 visudo？→ 自带语法校验防锁死；vim 直改出错 sudo 全失效
8. UID 划分？→ root=0，系统账号 1~999，普通用户 1000+

## 踩坑记录（面试素材）
- passwd 的 x 当成密码 → x 是占位符，密码哈希在 shadow
- usermod -G 丢附加组 → 必须 -aG 追加
- useradd 不加 -m 无家目录 → 登录报错
- vim 直接改 /etc/sudoers → 语法错误锁死 sudo；用 visudo
- shadow 里 ! 和 * 混淆 → ! 可解锁；* 是天生无密码服务账号
