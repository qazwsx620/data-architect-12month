# 订单数仓 · 全链路血缘图（mermaid 代码化，可进 Git）

```mermaid
graph LR
    subgraph 源层
        BZ[biz_user] --> DIM_USER[dim_user]
        BP[biz_product] --> DIM_PRODUCT[dim_product]
        BO[biz_order]
    end
    subgraph ODS层
        BO --> ODS[ods_order]
    end
    subgraph DWD层
        ODS --> DWD[dwd_order_detail]
    end
    subgraph DWS层
        DWD --> DWS_U[dws_user_daily]
        DWD --> DWS_P[dws_product_daily]
    end
    subgraph ADS层
        DWS_U --> ADS[ads_gmv_report]
    end
    subgraph 交付
        ADS --> CSV[ads_gmv_report.csv]
        ADS --> HTML[ads_report.html]
    end
```

## 影响分析示例
- 改 ods_order 结构 → 影响 dwd_order_detail → dws_user_daily / dws_product_daily → ads_gmv_report → CSV/HTML
- ⚠️ 注意 DWD 分叉成两条 DWS，数下游分支别漏（dws_product_daily 是易漏分支）
