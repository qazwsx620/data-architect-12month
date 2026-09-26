# Day16 · 环境变量 & Shell 进阶（export / PATH / 配置文件加载 / alias / 函数 / while / 数组 / bash -x）

> 阶段01 · 第1月 第3周 | 配套脚本见 `scripts/day16/` 目录，虚拟机实测通过。
> 背景：脚本环境排查、crontab 找不到命令、自定义命令别名，全靠本章；登录/非登录 shell 加载顺序是面试必考。

---

## 1. 环境变量基础

- 环境变量是进程运行时的键值对，影响程序行为
- 常见：`PATH`（命令搜索路径）、`HOME`、`USER`、`SHELL`、`LANG`
```bash
echo $PATH    # 多个目录冒号分隔，从左到右搜索命令
env           # 查看全部环境变量
```

### 普通变量 vs 环境变量（高频坑）
```bash
MY_VAR=hello                 # 普通变量：只在当前 shell 有效
export MY_VAR=hello          # 导出为环境变量：子进程继承
bash -c 'echo $MY_VAR'       # export 后子进程才能看到
```

## 2. 配置文件加载机制（面试必考）

| 类型 | 场景 | 加载配置 |
|------|------|----------|
| 登录 shell | ssh 登录、`su -` | `/etc/profile` → `~/.profile` → `~/.bashrc` |
| 非登录 shell | 终端再开 bash、脚本 | 只 `~/.bashrc` |

- `/etc/profile`：系统级，所有用户登录加载
- `~/.bashrc`：用户级，非登录 shell 也加载
- `~/.profile`：登录 shell 加载

### source 与直接执行（高频坑）
```bash
source ~/.bashrc    # ✅ 当前 shell 执行，立即生效
. ~/.bashrc         # ✅ 等价写法
bash ~/.bashrc      # ❌ 开子 shell，父 shell 不生效；且 .bashrc 内 return 报错
```
> 修改 .bashrc 后必须 `source` 或新开终端才能生效。

## 3. alias 命令别名
```bash
alias ll='ls -lh'            # 定义
alias                        # 查看全部
unalias ll                   # 删除
\grep x file                 # 反斜杠绕过别名用原命令
```
> ⚠️ 别名只对当前 shell 生效，不跨 shell 继承；永久生效写进 ~/.bashrc。

## 4. Shell 进阶：函数 / 数组 / while / case

```bash
# 函数
hello() { echo "Hello, $1"; }
hello vboxuser

# 数组
fruits=(apple banana orange)
echo ${fruits[@]}      # 全部元素
echo ${#fruits[@]}     # 元素个数

# while
i=1
while [ $i -le 3 ]; do echo "第 $i 次"; i=$((i+1)); done

# case（服务脚本标配）
case $1 in
    start) echo "启动" ;;
    stop)  echo "停止" ;;
    *)     echo "用法: $0 start|stop" ;;
esac
```

## 5. bash -x 脚本调试（面试重点）
```bash
bash -x script.sh
```
- 逐条打印命令（带 + 号）与变量展开，定位出错行
- 脚本内局部调试：`set -x` 开启 / `set +x` 关闭

## 6. 大厂专项：crontab 报 command not found

**根因**：crontab 环境是**最小环境**，不加载用户 shell 配置（.bashrc 的 PATH/别名/函数）。
**解决**：
```bash
# 方案1：脚本/命令用绝对路径（推荐）
/usr/local/bin/myscript.sh

# 方案2：crontab 顶部显式设置 PATH
PATH=/usr/local/bin:/usr/bin:/bin
* * * * * /usr/local/bin/myscript.sh
```

---

## 今日面试考点清单
1. 普通变量与 export 环境变量区别？→ 子进程能否继承
2. 登录/非登录 shell 加载哪些配置？→ profile+profile+bashrc vs 只 bashrc
3. source 与 bash 执行区别？→ 当前 shell 生效 vs 子 shell 不生效
4. 修改 .bashrc 如何立即生效？→ source ~/.bashrc
5. 别名跨 shell 吗？永久生效怎么做？→ 不跨，写 .bashrc
6. bash -x 作用？→ 逐条打印命令与展开，脚本调试
7. crontab command not found 根因与解决？→ 不加载 shell 配置，绝对路径/显式 PATH
8. ${#fruits[@]} 含义？→ 数组元素个数

## 踩坑记录（面试素材）
- 不 export 直接传子进程 → 变量为空
- bash ~/.bashrc 以为会生效 → 子 shell 执行父 shell 不变，且 return 报错
- 别名在子 shell 失效 → 别名不跨 shell，写 .bashrc
- crontab 里用自定义命令 → 最小环境找不到，绝对路径或 PATH
- 修改 .bashrc 不 source → 当前终端不生效
