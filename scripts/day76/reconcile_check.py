# 双链对账（概念演示）：实时 GMV vs 离线 GMV，同口径(status=2)核对
# 离线为权威兜底；实时近似；差异超阈值告警
import sys

realtime_gmv = float(input("实时GMV(来自Flink输出): "))
offline_gmv  = float(input("离线GMV(来自ads_gmv_report): "))
threshold = 0.0   # 差异阈值（生产按业务定，如 1% 或绝对额）

diff = abs(realtime_gmv - offline_gmv)
if diff > threshold:
    print(f"[告警] 对账失败: 实时={realtime_gmv} 离线={offline_gmv} 差异={diff}")
    print("优先排查实时链路: 丢数据/窗口未覆盖/迟到数据被丢/过滤条件")
else:
    print(f"[通过] 对账一致: 实时={realtime_gmv} 离线={offline_gmv}（口径status=2）")
