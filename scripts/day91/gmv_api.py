# Day91 实操：订单数仓数据服务 API（FastAPI 四要素落地，虚拟机实测通过）
# 独立环境：~/api_env（不能和 Airflow 的 venv 混用，opentelemetry-api 版本互斥）
# 接口：GET /v1/ads/gmv?start_date=&end_date=，Header 带 X-API-Key
# 实测：200 正常返回 4 天数据 / 401 无 key / 400 范围超限

from datetime import date

import pymysql
from fastapi import FastAPI, Query, HTTPException, Header

app = FastAPI(title="订单数仓数据服务")

API_KEY = "dw-demo-key"          # 生产：环境变量/密钥管理，别写死
DB = dict(host="127.0.0.1", port=3306, user="root", password="123456",
          database="dw_project", charset="utf8mb4")


@app.get("/v1/ads/gmv")
def get_gmv(
    start_date: date = Query(..., description="开始日期 YYYY-MM-DD"),
    end_date: date = Query(..., description="结束日期 YYYY-MM-DD"),
    x_api_key: str = Header(default=""),
):
    # ① 认证：API Key
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="invalid api key")
    # ② 参数校验：顺序 + 范围上限（防大查询）
    if start_date > end_date:
        raise HTTPException(status_code=400, detail="start_date > end_date")
    if (end_date - start_date).days > 366:
        raise HTTPException(status_code=400, detail="range too large (max 366 days)")
    # ③ 参数化查询 + 连接归还
    conn = pymysql.connect(**DB)
    try:
        with conn.cursor(pymysql.cursors.DictCursor) as cur:
            cur.execute(
                "SELECT stat_date, gmv, order_cnt FROM ads_gmv_report "
                "WHERE stat_date BETWEEN %s AND %s ORDER BY stat_date",
                (str(start_date), str(end_date)),
            )
            rows = cur.fetchall()
    finally:
        conn.close()
    return {"code": 0, "data": rows, "message": "ok"}
