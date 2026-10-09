# Day39 · Git 协作（分支 / 合并 / 冲突解决 / 回退）

> 模块三 · DevOps 阶段 Day1 | 配套脚本见 `scripts/day39/` 目录，虚拟机 ~/git_learn 实测通过。
> 背景：Git 是团队开发必备，分支与冲突解决是面试高频。

---

## 1. 分支的本质（面试必懂）

**分支 = 指向提交的指针**。在哪个分支上提交，提交就挂到哪个分支。

> 💥【坑】`git init -b main` 后如果在 feature 分支上做了根提交，main 从未指向任何提交 → `git switch main` 报 **fatal: 无效引用**。没有提交的分支是空指针，不构成分支。

## 2. 分支创建与切换

```bash
git branch feature-login       # 只创建，不切换
git switch feature-login       # 切换（Git 2.23+ 推荐）
git checkout feature-login     # 旧写法
git switch -c feature-login    # 创建+切换一步完成
```
> `switch -c`（create）= 一步；`branch` + `switch` = 两步。

## 3. 合并（merge）

```bash
# 快进合并 fast-forward：main 无新提交，指针直接前移
git switch main && git merge feature-login

# 非快进合并 merge commit：两分支都有各自提交 → 生成合并提交（双亲）
```

## 4. 冲突与解决（团队协作核心）

**冲突条件**：两个分支修改了同一文件的同一行 → Git 不知道保留哪个。

冲突标记：
```
<<<<<<< HEAD
v2: main 分支修改
=======
v2: feature 分支修改
>>>>>>> feature-login
```

**解决三步**：
```bash
# 1. 手动编辑文件：保留想要的版本，删掉三行标记
echo "v2: main 分支修改" > app.py
# 2. 标记已解决
git add app.py
# 3. 提交合并
git commit -m "merge: 解决冲突"
```

## 5. 回退（reset 三级）

| 参数 | 提交 | 暂存区 | 工作区 |
|------|------|--------|--------|
| --soft | 回退 | 保留 | 保留 |
| --mixed（默认） | 回退 | 清空 | 保留 |
| --hard | 回退 | 清空 | 清空 |

```bash
git reset --soft HEAD~1    # 撤销提交，修改留暂存
git reset HEAD app.py      # 取消暂存
git checkout -- app.py     # 丢弃工作区修改（危险）
git reset --hard HEAD~1    # 全部丢弃 ⚠️永久
```
> `--hard` 会永久丢弃修改，慎用；后悔可用 `git reflog` 找回。

---

## 今日面试考点清单
1. 分支本质？→ 指向提交的指针；空分支无效引用
2. switch -c vs branch+switch？→ 一步 vs 两步
3. 冲突条件与标记？→ 同文件同行；<<<<<<< ======= >>>>>>>
4. 冲突解决三步？→ 改文件 → git add → git commit
5. reset 三级？→ soft/mixed/hard 提交暂存工作区

## 踩坑记录（面试素材）
- 根提交落错分支 → 先 switch 再提交
- 空分支无效引用 → 无提交不构成分支
- 冲突不会自动合并 → 必须手动解决后 commit
- --hard 误用 → 永久丢失，先备份/reflog
- merge 快进 vs 合并提交 → 有无分叉决定
