# 订单数仓 · 数据血缘关系（Day51 梳理）

## 血缘图

```
biz_user ─────────────┐
biz_product ──────────┤ (全量/增量抽取)
biz_order ────────────┴──→ ods_order ──→ dwd_order_detail ──→ dws_user_daily ──→ ads_gmv_report ──→ CSV/HTML
                                                              └─→ dws_product_daily ──→ (预留：商品报表)
```

## 各节点说明

| 节点 | 类型 | 加工动作 |
|------|------|----------|
| biz_user / biz_product / biz_order | 业务源表 | 数据来源 |
| ods_order | 原始层 | 全量/增量抽取（原样入库） |
| dwd_order_detail | 明细层 | 清洗（类型/去重/缺失/枚举映射） |
| dws_user_daily | 汇总层 | 按用户-日汇总（GMV口径） |
| dws_product_daily | 汇总层 | 按商品-日汇总（GMV口径） |
| ads_gmv_report | 应用层 | 报表加工（GMV/订单量/客单价） |
| CSV/HTML | 最终去向 | 报表下发/汇报 |

## 血缘的用途（面试答案）
1. **出问题快速定位**：ADS 数字错 → 反查 DWS → DWD → ODS → 业务源
2. **评估影响面**：改某表 → 知道影响哪些下游报表
3. **审计追溯**：数据从哪来、谁加工的，可追溯

## 排查路径（自下向上）
```
业务库 → ODS → DWD → DWS → ADS
   ↑      ↑     ↑     ↑     ↑
   先查来源  逐层向上验证  最后看报表
```
