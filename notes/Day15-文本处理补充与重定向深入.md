# Day15 · 文本处理补充 & 输入输出重定向深入（sort / uniq / cut / wc / tr / tee / 重定向 / 管道）

> 阶段01 · 第1月 第3周 | 配套脚本见 `scripts/day15/` 目录，虚拟机实测通过。
> 背景：日志分析、报表统计、脚本输出管理全靠本章；awk/sed 已在 Day03 学完，本章是补全文本工具 + 重定向深入。

---

## 1. 文本处理补充工具

### sort 排序
```bash
sort file.txt        # 字典序排序
sort -n file.txt     # 按数字大小排序（重要！）
sort -r file.txt     # 降序
sort -k2 file.txt    # 按第 2 列排序
sort -rn             # 合并简写：数字排序 + 降序（短参数可合并）
```
> ⚠️【易混淆坑】不写 `-n` 数字按字典序排，10 会排在 2 前面。

### uniq 去重（只去相邻重复！）
```bash
uniq file.txt        # 去连续重复行
uniq -c file.txt     # 统计每行出现次数
```
> ⚠️【易混淆坑】uniq 只去**相邻**重复，必须先 `sort` 再 `uniq` 才能全量去重计数。

### cut 按列/字符截取
```bash
cut -d: -f1 /etc/passwd   # 冒号分隔取第 1 列
cut -c1-5 file.txt        # 取每行前 5 个字符
```
> 区分：awk -F 按分隔符取列（Day03）；cut -c 按字符位置截取。

### wc 统计
```bash
wc -l file.txt    # 行数
wc -w file.txt    # 单词数
wc -c file.txt    # 字节数
```

### tr 字符替换/删除
```bash
tr 'a-z' 'A-Z' < file.txt    # 小写转大写
tr -d '\r' < win.txt > lin.txt  # 删回车符，Windows(\r\n) 转 Linux(\n)
```

### tee 一箭双雕
```bash
echo "hello" | tee out.txt      # 屏幕 + 文件同时输出
echo "hello" | tee -a out.txt   # -a 追加
```
> tee 与 `>` 区别：tee 同时输出屏幕与文件；`>` 只写文件不显示。

## 2. 重定向深入（面试重点）

标准输入输出：
- stdin（0）标准输入
- stdout（1）标准输出
- stderr（2）标准错误

```bash
命令 > file       # stdout 覆盖写入
命令 >> file      # stdout 追加
命令 2> file      # stderr 单独重定向
命令 2>&1         # stderr 合并到 stdout
命令 > file 2>&1  # stdout+stderr 都进文件（正确顺序）
命令 &> file      # bash 简写，等价上面
```
> ⚠️【高频坑】`2>&1` 与 `>` 的顺序：
> ```bash
> 命令 > file 2>&1    # ✅ 先 stdout→file，再 stderr→stdout(=file)，都进文件
> 命令 2>&1 > file    # ❌ 先 stderr→stdout(终端)，再 stdout→file，stderr 仍打终端
> ```

## 3. 管道组合实战

```bash
# 统计日志错误码出现次数，降序取前 3
grep "error" /tmp/app.log | awk '{print $2}' | sort | uniq -c | sort -rn | head -3
```
管道全家桶：过滤 → 提取列 → 排序 → 去重计数 → 次数降序 → 取前 N。
> 大厂场景：接口错误码 Top10 报告 = 上面管道 + tee 落盘 + 邮件/告警。

---

## 今日面试考点清单
1. sort 不写 -n 会怎样？→ 按字典序，10 排在 2 前面
2. uniq -c 之前为什么必须 sort？→ uniq 只去相邻重复
3. sort -rn 与 sort -n -r 一样吗？→ 一样，短参数合并简写
4. 2>&1 顺序坑？→ `> file 2>&1` 全进文件；`2>&1 > file` 错误仍打终端
5. 两种写法把 stdout+stderr 都写文件？→ `> file 2>&1` 与 `&> file`
6. tee 与 > 区别？→ 双输出（屏幕+文件）vs 只写文件
7. tr -d '\r' 作用？→ 删回车符，Windows 换行转 Linux
8. cut -d 与 cut -c 区别？→ 按分隔符取列 vs 按字符位置截取

## 踩坑记录（面试素材）
- sort 忘 -n → 数字按字典序排错
- uniq 不先 sort → 分散的重复行去不掉
- 2>&1 > file 顺序反 → stderr 还在终端，以为丢日志
- 误以为 tee 是 -a 才追加 → tee 默认覆盖文件，-a 追加
- 混淆 awk -F 与 cut -c → 一个按分隔符取列，一个按字符位置
