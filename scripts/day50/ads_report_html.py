# Day50 实操③：ADS 报表 → HTML 可视化（自包含，虚拟机实测通过）
# 生成 ads_report.html，浏览器直接打开

import pymysql
from config import DW_CONFIG


def build_html():
    conn = pymysql.connect(**DW_CONFIG)
    cursor = conn.cursor()
    cursor.execute("SELECT stat_date, gmv, order_cnt, avg_amount FROM ads_gmv_report ORDER BY stat_date")
    rows = cursor.fetchall()
    conn.close()

    # 计算条形图比例（最高 GMV 为 100%）
    max_gmv = max(r[1] for r in rows) if rows else 1

    bars = ""
    table_rows = ""
    total_gmv = 0
    total_cnt = 0
    for date, gmv, cnt, avg in rows:
        pct = round(gmv / max_gmv * 100, 1)
        bars += f'''
        <div class="row">
          <div class="date">{date}</div>
          <div class="bar-wrap">
            <div class="bar" style="width:{pct}%">{gmv}</div>
          </div>
        </div>'''
        table_rows += f"<tr><td>{date}</td><td>{gmv}</td><td>{cnt}</td><td>{avg}</td></tr>"
        total_gmv += gmv
        total_cnt += cnt

    html = f"""<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="utf-8">
<title>订单数仓 · 每日GMV报表</title>
<style>
  body {{ font-family: sans-serif; max-width: 720px; margin: 40px auto; }}
  h1 {{ color: #333; }}
  .row {{ display: flex; align-items: center; margin: 8px 0; }}
  .date {{ width: 110px; color: #666; }}
  .bar-wrap {{ flex: 1; background: #f0f0f0; border-radius: 4px; }}
  .bar {{ background: #4caf50; color: #fff; padding: 8px 10px; border-radius: 4px; min-width: 60px; }}
  table {{ border-collapse: collapse; margin-top: 24px; width: 100%; }}
  th, td {{ border: 1px solid #ddd; padding: 8px; text-align: right; }}
  th {{ background: #f7f7f7; }}
  .total {{ margin-top: 16px; color: #555; }}
</style>
</head>
<body>
  <h1>订单数仓 · 每日 GMV 报表</h1>
  <h3>GMV 趋势（条形图）</h3>
  {bars}
  <h3>明细表</h3>
  <table>
    <tr><th>日期</th><th>GMV</th><th>订单量</th><th>客单价</th></tr>
    {table_rows}
  </table>
  <p class="total">合计：总 GMV = {total_gmv} 元，总订单量 = {total_cnt} 单，
     整体客单价 = {round(total_gmv / total_cnt, 2) if total_cnt else 0} 元</p>
</body>
</html>"""

    with open("ads_report.html", "w", encoding="utf-8") as f:
        f.write(html)
    print("已生成 ads_report.html")


if __name__ == "__main__":
    build_html()
