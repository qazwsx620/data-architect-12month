# Day13 · Linux 文件查找与定位（which / whereis / locate / find / xargs）

> 阶段01 · 第1月 第2周 | 配套脚本见 `scripts/day13/` 目录，虚拟机实测通过。
> 背景：磁盘告警定位大文件、清理过期日志、批量处理文件，全靠本章；四个查找命令对比是面试必考。

---

## 1. 四个查找命令对比（必背）

| 命令 | 查找对象 | 检索来源 | 特点 |
|------|----------|----------|------|
| which | 可执行程序（命令） | PATH 环境变量目录 | 只找二进制命令 |
| whereis | 命令、源码、man 手册 | 预定义数据库 | 找命令+帮助文档 |
| locate | 所有文件/目录 | mlocate.db 数据库 | 速度极快，**非实时** |
| find | 所有文件/目录 | 磁盘实时遍历 | 慢但功能最强，条件丰富 |

> ⚠️【易混淆坑】locate 找不到刚新建的文件：数据库每日自动更新；手动刷新：
```bash
sudo updatedb
```
> ⚠️ updatedb 默认**忽略 /tmp、/proc、/sys**，在 /tmp 新建文件即使 updatedb 也搜不到。

## 2. find 基础语法

```bash
find [起始目录] [匹配条件] [动作]
```
默认动作 `-print` 打印文件名；权限不足报错可用 `2>/dev/null` 屏蔽。

### 按名称
```bash
find /tmp -name "*.txt"      # 区分大小写
find /tmp -iname "*.TXT"     # 忽略大小写
```

### 按类型
```bash
find /tmp -type f    # 普通文件
find /tmp -type d    # 目录
find /tmp -type l    # 软链接
```

### 按大小（+ 大于 / - 小于，单位 k M G）
```bash
find /tmp -size +1M    # 大于 1M
find /tmp -size -1M    # 小于 1M
```

### 按时间（面试重点）
| 参数 | 含义 | 例子 |
|------|------|------|
| -mtime / -mmin | 内容修改时间（天/分钟） | `-mtime -1` 1天内；`-mmin +30` 30分钟前 |
| -ctime | 元数据变更（权限/属主，内容不变也算） | `chmod` 后 ctime 变 mtime 不变 |
| -atime | 读取访问时间（cat 查看即更新） | - |

> ⚠️【易混淆坑】find 里 1 天 = 24 小时，不是自然日。

### 按权限/属主
```bash
find /tmp -user vboxuser     # 属主
find /tmp -perm 644          # 权限严格等于
find /tmp -perm /444         # 任意一类有读权限
```

## 3. find 逻辑运算（面试重点）

```bash
find /tmp -type f -name "*.txt" -and -size +0c       # 与（默认）
find /tmp -type f \( -name "*.txt" -o -name "*.log" \)  # 或，括号必须转义且带空格
find /tmp -type f ! -name "*.txt"                    # 取反
```
> ⚠️【易混淆坑】`\(` `\)` 必须反斜杠转义，且**前后必须有空格**，否则 shell 解析报错。

## 4. find 动作与 xargs

### -exec 逐个执行
```bash
find /tmp -name "*.txt" -exec rm {} \;
```
- `{}` 匹配到的文件；`\;` 结尾标记不能省略
- 缺点：**每个文件启动一次进程**，文件量大时多次 fork，性能差

### xargs 批量传参（推荐）
```bash
find /tmp -name "*.txt" | xargs rm
```
- 把多个文件名**打包一次性传给命令**，进程开销小，效率高

### 带空格文件名（高频坑）
```bash
find /tmp -type f -print0 | xargs -0 ls -l
```
- `-print0`：find 用空字符 `\0` 分隔文件名
- `-0`：xargs 以空字符为分隔，兼容空格/特殊符号

### -delete 直接删除（高危！）
```bash
find /tmp -name "test_*.txt" -delete
```
> ⚠️ 必遵流程：**先不带 -delete 执行 find 预览匹配结果，确认无误再加 -delete**，防止误删。

---

## 今日面试考点清单
1. which/whereis/locate/find 区别？→ PATH 程序 / 程序+man / 数据库非实时 / 实时遍历功能最强
2. locate 为什么找不到新文件？→ 数据库未更新，sudo updatedb 刷新（/tmp 默认忽略）
3. -mtime 与 -ctime 区别？→ 内容修改 vs 元数据（权限/属主）修改
4. -exec 与 xargs 区别？→ 逐个启动进程性能差 vs 批量传参效率高
5. 带空格文件名怎么处理？→ find -print0 | xargs -0
6. \( \) 为什么必须带空格？→ find 语法标记是独立参数，紧贴字符会解析失败
7. -delete 使用注意？→ 先预览匹配结果再删，防误删
8. 1 天是多少？→ find 里 1 天 = 24 小时

## 踩坑记录（面试素材）
- locate 搜不到 /tmp 文件 → updatedb 默认忽略临时目录
- find 权限不足刷屏 → 2>/dev/null 或 sudo
- \( \) 不带空格语法报错 → 括号前后必须有空格
- 管道 xargs 处理带空格文件名出错 → -print0 | xargs -0
- 直接 -delete 误删 → 先预览再删
