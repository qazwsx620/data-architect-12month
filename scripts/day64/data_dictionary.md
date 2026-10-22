# 订单数仓 · 数据字典（业务元数据）

## 核心口径（全仓统一）
- GMV = 已支付（status=2）订单金额合计
- 订单量 = 已支付订单笔数
- 客单价 = GMV ÷ 订单量
- 状态枚举：1=未支付 2=已支付 3=已取消

## 分层说明
| 层 | 表 | 粒度 | 业务含义 |
|----|-----|------|----------|
| ODS | ods_order | 一单一行 | 原始订单（含 raw_data 兜底） |
| DWD | dwd_order_detail | 一单一行 | 清洗后明细（status_name 可读） |
| DWS | dws_user_daily | 用户+日 | 用户每日汇总（已支付口径） |
| DWS | dws_product_daily | 商品+日 | 商品每日汇总（已支付口径） |
| ADS | ads_gmv_report | 日 | 每日 GMV 报表 |

## 字段字典（重点字段）
| 表.字段 | 类型 | 含义 | 口径/枚举 |
|---------|------|------|----------|
| ods_order.raw_data | varchar | 原始行兜底 | 整行 CSV 原文 |
| dwd_order_detail.status_name | varchar | 状态可读名 | 1未支付/2已支付/3已取消 |
| dws_user_daily.total_amount | decimal | 用户日金额 | 只含已支付 |
| ads_gmv_report.avg_amount | decimal | 客单价 | GMV/订单量 |

## 治理规则
- 口径变更必须走评审，同步更新本字典
- 命名规范：层前缀（ods_/dwd_/dws_/ads_）+ 业务名
- 影响分析：改表/改口径前，先看 lineage.md 血缘全部分支
