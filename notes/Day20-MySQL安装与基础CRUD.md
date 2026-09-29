# Day20 · MySQL 安装与基础 CRUD（安装 / 库表 / 增删改查 / 逻辑架构）

> 阶段01 · 第2月 | 配套脚本见 `scripts/day20/` 目录，虚拟机实测通过。
> 背景：进入 MySQL 模块，从安装到基础增删改查，以及面试必考的逻辑架构分层。

---

## 1. MySQL 8.0 安装（Ubuntu 22.04）

```bash
sudo apt update
sudo apt install mysql-server -y
sudo systemctl status mysql     # active (running)
```
> ⚠️【易混淆坑】Ubuntu 的 MySQL root 默认 **auth_socket 认证**：`sudo mysql` 免密进入（靠系统用户身份）；CentOS 默认 root 需设密码。两者认证方式不同。

### 修改 root 为密码认证（客户端/远程连接需要）
```sql
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '密码';
FLUSH PRIVILEGES;
exit;
-- 之后用密码登录
mysql -uroot -p密码
```
> 说明：mysql_native_password 传统密码认证，兼容旧客户端；MySQL8 默认推荐 caching_sha2_password。命令行写密码有安全告警，生产用 `mysql -uroot -p` 回车再输入。

## 2. 库的基本操作

```sql
CREATE DATABASE test_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SHOW DATABASES;
USE test_db;
SELECT DATABASE();
DROP DATABASE IF EXISTS test_db;
```
> ✅ utf8mb4 才是完整 utf8（4 字节，支持 emoji）；旧的 utf8 最多 3 字节。面试高频。

## 3. 建表与数据类型

```sql
CREATE TABLE user(
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    age TINYINT UNSIGNED,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
SHOW TABLES;
DESC user;
```
- `AUTO_INCREMENT`：主键自增，每次新增自动 +1
- `DEFAULT CURRENT_TIMESTAMP`：不填时间自动取当前
- `TINYINT UNSIGNED`：无符号，不能存负数

## 4. INSERT 插入

```sql
-- 指定字段插入（推荐，扩展性好）
INSERT INTO user(username,age) VALUES ('zhangsan',20);

-- 批量插入（性能更高，减少网络交互）
INSERT INTO user(username,age) VALUES ('lisi',22),('wangwu',24);
```
> 字符串用单引号；id 自增、create_time 有默认值，可不写。

## 5. SELECT 查询

```sql
SELECT id,username,age FROM user;           -- 指定列，避免 SELECT *
SELECT * FROM user WHERE age > 20;          -- 条件过滤
SELECT * FROM user WHERE username='lisi';   -- 等值
SELECT * FROM user WHERE age>20 AND age<25; -- 多条件
```
> 尽量避免 SELECT *，只查需要字段。WHERE 过滤行，不能给聚合结果过滤（用 HAVING）。

## 6. UPDATE 更新

```sql
UPDATE user SET age=23 WHERE username='lisi';
```
> ⚠️【重大坑】省略 WHERE 会更新**整张表**，生产事故源头。先 SELECT 验证条件再 UPDATE。

## 7. DELETE 删除

```sql
DELETE FROM user WHERE id=3;
```
> ⚠️ DELETE 不加 WHERE 清空全表。DELETE 是 DML，删行，**不重置自增**；TRUNCATE 是 DDL，清空全表、重置自增、锁表、速度更快。

## 8. MySQL 逻辑架构分层（面试大题）

从上到下 4 层：
1. **连接层**：TCP 连接、账号密码认证、权限校验
2. **服务层**：SQL 解析、语法检查、查询优化器、生成执行计划（MySQL8 已移除查询缓存）
3. **引擎层**：插件式存储引擎，表级别。InnoDB（默认：事务/行锁/外键/崩溃恢复）、MyISAM（表锁/无事务）
4. **存储层**：底层磁盘文件（数据/索引/日志）

> ✅ 引擎是**表级别**，不是库级别；同一库不同表可用不同引擎，但生产统一 InnoDB。
> 口述版：客户端连接经连接层认证 → SQL 交服务层解析优化 → 交存储引擎 → 引擎与存储层读写磁盘。

---

## 今日面试考点清单
1. Ubuntu MySQL root 默认认证？→ auth_socket，sudo mysql 免密
2. 为什么用 utf8mb4？→ 完整 utf8，4 字节支持 emoji
3. UPDATE/DELETE 最容易出事故？→ 不加 WHERE 全表操作
4. DELETE 与 TRUNCATE 区别？→ DML 删行不重置自增 vs DDL 清空重置自增锁表
5. MySQL 逻辑架构四层？→ 连接层/服务层/引擎层/存储层
6. 引擎级别？→ 表级别，InnoDB 默认
7. 避免 SELECT * 原因？→ 只查需要的字段，减少 IO 带宽

## 踩坑记录（面试素材）
- sudo mysql 免密以为没密码 → auth_socket 认证，靠系统身份
- 用旧 utf8 存 emoji 报错 → 用 utf8mb4
- UPDATE/DELETE 漏 WHERE → 全表更新/清空，生产事故
- 以为引擎是库级别 → 实际表级别
- 命令行 -p 直接带密码 → 有安全告警，回车再输
