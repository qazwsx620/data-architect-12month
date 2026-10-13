# Day48 · 数仓项目·DWD 层 ETL：清洗规范化（ODS → DWD）

> 模块四 · 数仓工程 Day5 | 配套脚本见 `scripts/day48/dwd_transform.py`（虚拟机实测通过）。
> 背景：订单数仓第二层——ODS 原始数据清洗成规范明细，供下游复用。

---

## 1. DWD vs ODS（面试必答）

| | ODS | DWD |
|--|-----|-----|
| 内容 | 原样数据（含脏数据） | 清洗后规范数据 |
| 使命 | 可追溯 | 供下游复用 |
| 状态 | status 数字 1/2/3 | status_name 可读"已支付" |
| 口径 | 无 | 统一 |

> 一句话：ODS 是"原材料仓库"，DWD 是"净菜车间"——洗好、切好、标好，下游直接炒菜。

## 2. 清洗规则清单（5类，面试高频）

| 规则 | 例子 | 为什么 |
|------|------|--------|
| 类型转换 | amount 字符串→DECIMAL | 保证可计算 |
| 去重 | 同一 order_id 重复 | 主键唯一、不重复计算 |
| 缺失处理 | status 空→默认1；amount 空→0 | 不留脏数据 |
| 枚举映射 | 1→未支付、2→已支付、3→已取消 | 业务可读 |
| 口径统一 | 金额保留2位、日期统一 YYYY-MM-DD | 下游同标准 |

> 三组动作要分清：**类型转换**（amount 数值化）、**枚举映射**（status 数字→可读名）、**格式统一**（order_date 日期格式）。

## 3. 清洗脚本 dwd_transform.py 核心

```python
STATUS_MAP = {1: "未支付", 2: "已支付", 3: "已取消"}

def transform(df):
    # 1. 类型转换
    df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
    # 2. 格式统一
    df["order_date"] = pd.to_datetime(df["order_date"]).dt.strftime("%Y-%m-%d")
    # 3. 去重
    df = df.drop_duplicates(subset=["order_id"])
    # 4. 缺失处理
    df["status"] = df["status"].fillna(1).astype(int)
    df["amount"] = df["amount"].fillna(0).round(2)
    # 5. 枚举映射
    df["status_name"] = df["status"].map(STATUS_MAP)
    return df
```

加载幂等：按 order_id 先删后插（重复执行结果一致、行数不变）。

## 4. 运行验证结果

| 项目 | 结果 |
|------|------|
| ODS → DWD | 9 行 ✅ |
| status_name | 已支付/未支付/已取消 可读 ✅ |
| amount | 数值化保留2位 ✅ |
| order_date | 统一 YYYY-MM-DD ✅ |

---

## 今日面试考点清单
1. ODS vs DWD？→ 原材料仓库 vs 净菜车间
2. 清洗规则5类？→ 类型/去重/缺失/映射/口径
3. 映射 vs 类型转换？→ status映射 / amount转换
4. 幂等加载？→ 按主键先删后插
5. 规则谁定义？→ 业务方定义口径 + 数据团队落地

## 踩坑记录（面试素材）
- 把枚举映射当类型转换 → 概念混淆，映射是数字→可读名
- 漏格式统一 → 日期格式混乱，下游 join 对不上
- 不幂等加载 → 重复跑数据翻倍
- ODS/DWD 职责混用 → ODS 也做清洗，丢失可追溯性
