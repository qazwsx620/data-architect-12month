# Day21 · MySQL 数据类型与约束（数值/字符串/日期 / 五大约束 / NULL坑）

> 阶段01 · 第2月 | 配套脚本见 `scripts/day21/` 目录，虚拟机实测通过。
> 背景：字段类型选型、约束设计决定表结构质量；类型选择与约束原理是面试必考。

---

## 1. 数值类型

| 类型 | 字节 | 范围 | 适用 |
|------|------|------|------|
| TINYINT | 1 | -128~127；UNSIGNED 0~255 | 年龄、状态标记(0/1) |
| INT | 4 | -21亿~21亿 | 普通 ID、大多数业务主键 |
| BIGINT | 8 | 极大 | 海量数据/分库分表，防溢出；大厂统一 BIGINT |

> ✅ 面试：INT 上限 21 亿，数据量超过会溢出，必须 BIGINT。

## 2. 字符串类型

- **CHAR(n)**：定长，固定占 n 字符空间，不足补空格。适合手机号、身份证号等固定长度
- **VARCHAR(n)**：变长，占用 = 实际字符长度 + 少量开销。适合用户名等长短不一
> ✅ 面试：MySQL5.0 以后 VARCHAR(n) 的 n 是**字符数**不是字节数；utf8mb4 一个字符最多 4 字节。

## 3. 日期时间类型

| 类型 | 说明 |
|------|------|
| DATE | 仅日期 YYYY-MM-DD |
| DATETIME | 日期+时间，范围大、不受时区影响，业务最常用 |
| TIMESTAMP | 时间戳，范围 1970~2038，随时区转换，2038 溢出，新项目尽量不用 |

## 4. 五大约束

1. **PRIMARY KEY**：唯一标识一行，**非空+唯一**，一张表一个主键
2. **NOT NULL**：字段不能为 NULL
3. **UNIQUE**：字段值不能重复，**允许 NULL**（可多个 NULL）
4. **DEFAULT**：不填时自动填预设值
5. **FOREIGN KEY**：子表引用主表主键，保证引用完整性

> ⚠️【面试重点】互联网业务**大多禁用外键**：外键降低写入性能、并发易锁表；改由业务代码做逻辑校验。

```sql
CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '订单主键',
    user_id BIGINT NOT NULL COMMENT '用户id',
    order_no VARCHAR(32) UNIQUE NOT NULL COMMENT '订单编号，唯一',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '订单状态，默认1正常',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
);
```

## 5. 约束验证实验（实测）

- 唯一冲突：`Duplicate entry 'xxx' for key 'orders.order_no'`
- 非空缺失：`Field 'user_id' doesn't have a default value`
- 外键失效：`Cannot add or update a child row: a foreign key constraint fails`

## 6. NULL 的坑点（面试高频）

- NULL = 未知值，**不是空字符串 ''，也不是 0**
- 判断 NULL 必须用 `IS NULL` / `IS NOT NULL`；`= NULL` 永远查不到结果
- 业务字段尽量 NOT NULL + 默认值，索引里 NULL 占空间

---

## 今日面试考点清单
1. TINYINT UNSIGNED 范围？→ 0~255
2. CHAR 与 VARCHAR 区别？→ 定长补空格 vs 变长省空间
3. VARCHAR(n) 的 n 是字符还是字节？→ 字符数
4. INT 溢出怎么办？→ BIGINT
5. DATETIME 与 TIMESTAMP 区别？→ 范围/时区/2038
6. 主键与唯一约束区别？→ 主键唯一+非空；唯一可 NULL
7. 为什么业务不用外键？→ 性能低、并发锁表，代码层校验
8. 判断 NULL 用 = 可以吗？→ 不行，IS NULL

## 踩坑记录（面试素材）
- 用 = NULL 查询 → 永远空集，必须 IS NULL
- INT 存大 ID 溢出 → 海量表用 BIGINT
- varchar(n) 当字节数 → 是字符数
- 加外键导致写入锁表 → 互联网业务代码层校验
- TIMESTAMP 到 2038 → 新项目用 DATETIME
