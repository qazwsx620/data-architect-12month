#!/bin/bash
# Day39 演示：Git 协作（分支/合并/冲突/回退）
# 用法：在 ~/git_learn 下按顺序执行，模拟团队协作全流程

# ====== 1. 初始化 ======
mkdir -p ~/git_learn && cd ~/git_learn
git init -b main
git config user.name "vboxuser"
git config user.email "vboxuser@local"

# ====== 2. 根提交 ======
echo "v1: 主分支第一版" > app.py
git add app.py
git commit -m "init app"

# ====== 3. 分支开发 ======
git branch feature-login
git switch feature-login
echo "def login(): pass" >> app.py
git add app.py
git commit -m "add login"

# ====== 4. fast-forward 合并 ======
git switch main
git merge feature-login
git log --oneline --graph --all

# ====== 5. 制造冲突 ======
echo "v2: main 分支修改" > app.py
git add app.py && git commit -m "main: 修改第一行"

git switch feature-login
echo "v2: feature 分支修改" > app.py
git add app.py && git commit -m "feature: 修改第一行"

git switch main
git merge feature-login   # → 冲突 CONFLICT

# ====== 6. 解决冲突 ======
cat app.py                # 查看 <<<<<<< ======= >>>>>>>
echo "v2: main 分支修改" > app.py   # 保留 main 版本
git add app.py
git commit -m "merge: 解决冲突，保留main版本"
git log --oneline --graph --all

# ====== 7. 回退演示 ======
echo "临时提交" >> app.py
git add app.py && git commit -m "temp commit"
git reset --soft HEAD~1   # 撤销提交，修改留暂存
git status
git reset HEAD app.py     # 取消暂存
git checkout -- app.py    # 丢弃工作区修改
git log --oneline | head -3
