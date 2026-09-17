# Day02 · Shell 脚本基础（变量 / 位置参数 / if / for / 命令替换）

> 阶段01 · 第1月 第2周 | 配套脚本见 `scripts/` 目录，全部为虚拟机实测通过版本。

---

## 1. 脚本基础结构

```bash
#!/bin/bash
# 这是一行注释
echo "hello"
```

- `#!/bin/bash`（shebang）：告诉操作系统用 bash 解释器执行本脚本，必须写在第一行
- `#`：注释，Shell 不会执行
- 写完脚本要加执行权限：`chmod +x 脚本名`，然后 `./脚本名` 运行

## 2. Shell 变量

```bash
log_level="error"        # 定义变量：等号两边不能有空格！
echo $log_level          # 使用变量：$变量名
echo "日志级别：${log_level}_type"   # 大括号拼接，避免与后面文本粘连
```

> ⚠️ 重点坑：`log_level = error` 会报错，等号两边有空格时 Shell 会把 `log_level` 当成命令执行。
> - 双引号 `"$var"`：会解析变量值
> - 单引号 `'$var'`：原样输出，不解析
> - `${var}` 大括号写法：变量后紧跟文本时推荐，防止识别错误

## 3. 位置参数（脚本传参）

```bash
echo "脚本名称：$0"      # 脚本本身名字
echo "第一个参数：$1"     # 第1个参数
echo "第二个参数：$2"     # 第2个参数
echo "参数总数量：$#"     # 参数个数
echo "全部参数：$@"       # 所有参数列表
```

执行 `./pos_demo.sh error warn`：
- `$0` = `./pos_demo.sh`，`$1` = `error`，`$2` = `warn`，`$#` = `2`，`$@` = `error warn`

## 4. if 条件判断

```bash
if [ 条件 ]; then
  # 成立执行
elif [ 条件 ]; then
  # 第二个条件成立执行
else
  # 都不成立执行
fi
```

> ⚠️ 重点坑：`[` 后面、`]` 前面**必须有空格**，`[ $1 == "error" ]` 写错成 `[$1=="error"]` 会报错（`[` 本质是一条命令）。

常用判断：
| 类型 | 写法 | 含义 |
|------|------|------|
| 字符串 | `[ $a == "test" ]` | 字符串相等 |
| 文件 | `[ -f test.log ]` | 是普通文件且存在 |
| 目录 | `[ -d logs ]` | 是目录 |
| 数字 | `[ $# -ne 1 ]` | 个数不等于 1 |
| 数字 | `-eq` `-ne` `-gt` `-lt` | 等于 / 不等于 / 大于 / 小于 |

- `exit 1`：退出脚本并返回状态码 1（常用于参数校验失败后终止，防止后续继续执行）

## 5. for 循环

```bash
for level in error warn info debug
do
  echo "日志级别：$level"
done
```

- `do` 开始循环体，`done` 是循环结束标记
- 依次把列表中的值赋给 `level`，执行一遍 `do...done` 之间的命令

## 6. 命令替换

```bash
error_count=$(grep "error" test.log | wc -l)
```

- 执行 `$()` 内部的命令，**捕获输出结果**赋值给变量
- 推荐 `$(cmd)` 而非反引号 `` `cmd` ``：嵌套书写可读性更好，反引号嵌套需要大量转义

## 7. 用 cat 写入文件

```bash
cat > var_demo.sh <<'EOF'
#!/bin/bash
log_level="error"
echo $log_level
EOF
```

- `cat > 文件名 <<'EOF' ... EOF`：把中间内容原样写入文件
- `<<EOF`：会解析变量；`<<'EOF'`：原样写入不解析变量

## 8. 综合实战：日志关键词统计脚本（level_stat.sh）

需求：接收一个日志级别参数（error/warn），统计 test.log 中该关键词行数。

```bash
#!/bin/bash
if [ $# -ne 1 ];then
  echo "用法：./level_stat.sh [日志级别]"
  exit 1
fi
level=$1
if [ $level == "error" ] || [ $level == "warn" ];then
  count=$(grep $level test.log | wc -l)
  echo "test.log中关键词${level}的总行数是：$count"
else
  echo "不支持的日志级别"
fi
```

执行结果：
- `./level_stat.sh error` → `test.log中关键词error的总行数是：2`
- `./level_stat.sh abc` → `不支持的日志级别`

---

## 今日面试考点清单
1. `#!/bin/bash` 作用？→ 告诉操作系统用 bash 解释器运行
2. 变量定义为什么 `var = 123` 报错？→ 等号两边不能有空格
3. `$#` 代表什么？→ 传入参数的数量
4. `[ ]` 两边空格能省略吗？→ 不能，省略会报错
5. `$(cmd)` 叫什么、功能？→ 命令替换，捕获命令输出赋给变量
6. `-ne` 含义？→ 数字比较：不相等（not equal）
7. `set -e` 作用（思考题）？→ 脚本中任一命令执行失败立即退出（明天展开）

## 踩坑记录（面试素材）
- `[level == "warn"]` 缺空格 → `[level: 未找到命令`，`[` 后必须空格
- `[ level == "warn" ]` 变量忘加 `$` → 永远拿字符串 `level` 比较
- echo 命令漏写 → Shell 把 `日志级别：error` 当命令执行，报"未找到命令"
- `<<'EOF"` 引号不匹配 → 退出输入模式需 Ctrl+C，重新执行
