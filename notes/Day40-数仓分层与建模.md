# Day40 · 数仓基础：分层与建模（ODS/DWD/DWS/ADS / 事实表维度表 / 星型雪花）

> 模块三 · 数仓基础 Day1 | 配套脚本见 `scripts/day40/` 目录，虚拟机 MySQL 实测通过。
> 背景：数仓分层与维度建模是数据开发岗位面试必背理论。

---

## 1. 数仓分层（面试必背）

| 层级 | 全称 | 职责 | 示例 |
|------|------|------|------|
| ODS | 原始数据层 | 原样存储业务数据，不加工 | 订单表原始记录 |
| DWD | 明细数据层 | 清洗、规范化，最细粒度明细 | 清洗后订单明细 |
| DWS | 汇总数据层 | 按主题轻度汇总（用户/商品/日期） | 用户每日订单汇总 |
| ADS | 应用数据层 | 面向业务报表，高度汇总 | 用户月度消费报表 |

**数据流向**：业务库 → ODS → DWD → DWS → ADS
> 记忆：原始、明细、汇总、应用——从粗到细加工，从细到粗汇总。

**为什么要分层**：①结构清晰 ②数据可追溯 ③复用计算（DWS 一次加工多处用）④隔离变更（底层变了不影响上层）。

## 2. 四层建表（MySQL 实操）

```sql
-- ODS：原样存
CREATE TABLE ods_order (
    order_id BIGINT PRIMARY KEY, user_id BIGINT, order_no VARCHAR(32),
    amount DECIMAL(10,2), status TINYINT, create_time DATETIME
);
-- DWD：清洗规范化（status_name 枚举可读）
CREATE TABLE dwd_order_detail (
    order_id BIGINT PRIMARY KEY, user_id BIGINT, order_no VARCHAR(32),
    amount DECIMAL(10,2), status TINYINT,
    status_name VARCHAR(20) COMMENT '1-正常 2-退款',
    create_time DATETIME
);
-- DWS：按用户+日期轻度汇总
CREATE TABLE dws_user_daily (
    stat_date DATE, user_id BIGINT,
    order_cnt INT, amount_sum DECIMAL(12,2),
    PRIMARY KEY (stat_date, user_id)
);
-- ADS：业务报表
CREATE TABLE ads_user_report (
    user_id BIGINT PRIMARY KEY,
    total_cnt INT, total_amount DECIMAL(12,2)
);
```

## 3. 事实表 & 维度表

| | 事实表 | 维度表 |
|--|--------|--------|
| 内容 | 数字指标（金额/数量） | 描述属性（名称/城市） |
| 特点 | 不断增长 | 相对稳定 |
| 键 | 外键引用维度表 | 主键 |

## 4. 维度建模：星型 vs 雪花

- **星型**：1 事实表 + N 维度表**直接连接**（维度不细分）→ 少 join、查询快，**90% 场景首选**
- **雪花**：维度表**再细分**多级（城市→省份→国家）→ 规范化省空间，但多 join、查询慢

```sql
-- 星型模型：2 维度表 + 1 事实表
CREATE TABLE dim_user (user_id BIGINT PRIMARY KEY, user_name VARCHAR(50), city VARCHAR(50));
CREATE TABLE dim_product (product_id BIGINT PRIMARY KEY, product_name VARCHAR(100), category VARCHAR(50));
CREATE TABLE fact_order (
    order_id BIGINT PRIMARY KEY, user_id BIGINT, product_id BIGINT,
    amount DECIMAL(10,2), create_time DATETIME,
    FOREIGN KEY (user_id) REFERENCES dim_user(user_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
);
```

---

## 今日面试考点清单
1. 四层职责？→ 原始/明细/汇总/应用
2. 数据流向？→ 业务库→ODS→DWD→DWS→ADS
3. 事实表 vs 维度表？→ 数字指标增长 / 描述属性稳定
4. 星型 vs 雪花？→ 维度直连 vs 维度细分
5. 为什么要分层？→ 清晰/追溯/复用/隔离

## 踩坑记录（面试素材）
- ODS 就做清洗 → 违背"原样存储"，源头必须留底
- DWS 粒度不统一 → 每层都要定粒度和口径
- 事实表存描述字段 → 描述放维度表，事实表只放指标+外键
- 雪花模型滥用 → 查询慢，小维度直接星型
- 分层跳级 → 必须层层加工，不能 ODS 直接出 ADS
