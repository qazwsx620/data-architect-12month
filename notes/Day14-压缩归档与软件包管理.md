# Day14 · Linux 压缩归档 & 软件包管理（tar / zip / dpkg / apt）

> 阶段01 · 第1月 第3周 | 配套脚本见 `scripts/day14/` 目录，虚拟机实测通过。
> 背景：日志备份、应用部署、软件安装升级，全靠归档与包管理；归档≠压缩、apt vs dpkg 是面试高频。

---

## 1. 归档 vs 压缩（高频坑点）

- **归档（打包）**：把多个文件/目录合并成一个文件，**不减小体积**，tar 是归档工具
- **压缩**：算法减少文件占用空间，gzip / bzip2 / xz / zip 是压缩工具
- 日常 tar 常把**打包+压缩**一起做

## 2. tar 命令（核心）

| 参数 | 含义 |
|------|------|
| -c | 创建归档包 |
| -x | 解压/解包 |
| -v | 打印过程（文件列表） |
| -f | 指定包文件名，**必须放最后** |
| -z | gzip 压缩，`.tar.gz` / `.tgz` |
| -j | bzip2 压缩，`.tar.bz2` |
| -J | xz 压缩，`.tar.xz`（压缩率最高，最慢）|
| -C | 指定解压目标目录（大写） |

```bash
# 打包+压缩
tar -zcvf test.tar.gz /tmp/test
# 解压到当前目录
tar -zxvf test.tar.gz
# 解压到指定目录
tar -zxvf test.tar.gz -C /tmp/out
# 只查看包内文件，不解压
tar -ztvf test.tar.gz
```
> ⚠️【易混淆坑】`-f` 必须放所有参数最后（`-fzcv` 报错）；`-C` 大写，小写 c 是创建，含义完全不同。
> ⚠️ 打包绝对路径如 `/tmp/test` 会**自动去掉开头 `/`**，解压生成相对目录，防覆盖系统原文件（安全机制）。

**压缩率对比：** gzip(-z) < bzip2(-j) < xz(-J)，压缩率越高越慢。
**打包小技巧：** 先 `cd` 进目录再打包（`tar -zcvf ~/files.tar.gz .`），避免解压出深层嵌套目录。

## 3. zip / unzip

- tar：归档+压缩，保留 Linux 权限/属主，Linux/Unix 生态友好
- zip：跨平台（Windows 可直接解压），**不擅长保留 Linux 权限**

```bash
zip -r test.zip dir/          # 压缩
unzip test.zip                # 解压到当前目录
unzip test.zip -d /tmp/out2   # -d 指定解压目录（对应 tar 的 -C）
```

## 4. dpkg（底层本地 deb 工具，不处理依赖）

```bash
sudo dpkg -i xxx.deb     # 安装本地 deb 包
dpkg -l | grep nginx     # 查看已安装包
dpkg -L nginx            # 查看包安装的文件路径
sudo dpkg -r nginx       # 删除软件，保留配置
sudo dpkg -P nginx       # 彻底删除，连同配置（Purge）
```
> ⚠️ `dpkg -i` 缺依赖会报错，修复：`sudo apt -f install`

## 5. apt（上层联网工具，自动解决依赖）

```bash
sudo apt update           # 更新软件源索引（只刷清单，不升级软件）
sudo apt upgrade          # 升级所有已安装包
sudo apt install nginx    # 安装
sudo apt remove nginx     # 卸载，保留配置
sudo apt purge nginx      # 卸载+清理配置
apt search nginx          # 搜索
apt show nginx            # 查看信息
sudo apt autoremove       # 清理不再被依赖的残留软件包
sudo apt clean            # 清理已下载的 deb 安装包缓存
```
> ✅【面试高频】apt：联网、自动解决依赖、推荐日常使用；dpkg：本地 deb 包、不处理依赖、底层工具。
> 软件源文件：`/etc/apt/sources.list`，改源后必须 `sudo apt update` 刷新缓存。
> ⚠️ autoremove（清无用依赖包）与 clean（清 deb 缓存）别混淆。

---

## 今日面试考点清单
1. 归档与压缩区别？→ 归档合并不减小体积；压缩减小体积
2. tar 中 -f 为什么放最后？→ 后面紧跟包文件名，放中间解析出错
3. -C 作用？→ 指定解压目录，大写；小写 c 是创建
4. gzip/bzip2/xz 对应参数与后缀？→ -z .tar.gz / -j .tar.bz2 / -J .tar.xz
5. dpkg 与 apt 区别？→ 底层本地不处理依赖 vs 联网自动解决依赖
6. dpkg -r 与 -P 区别？→ 保留配置 vs 连同配置删除
7. apt autoremove 与 clean 区别？→ 清无用依赖包 vs 清 deb 安装包缓存
8. dpkg 装 deb 缺依赖怎么办？→ apt -f install 修复
9. 打包绝对路径为何去开头 /？→ 防解压覆盖系统原文件（安全机制）

## 踩坑记录（面试素材）
- 把归档当压缩，或 tar 说成压缩工具 → 归档≠压缩，tar 可组合压缩算法
- -f 放中间报错 → f 必须末尾
- -C 大小写混淆 → 大写指定目录，小写创建
- 绝对路径打包解压出深层嵌套目录 → 先 cd 进目录再打包
- dpkg -i 缺依赖报错 → apt -f install 修复
- autoremove 与 clean 混用 → 一个是清依赖包，一个是清安装包缓存
