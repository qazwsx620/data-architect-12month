# Day95 实操：质量平台雏形（规则库 + 引擎 + 结果/告警文件）
# 规则库：rules_v2.yaml（配置化，改规则不用改代码）
# 输出：quality_results.json（大盘数据源）+ alerts.log（告警文件）
# 实测：R001/R002/R003 PASS，R004（及时性，昨天无数据）FAIL 并写出告警

import json
import yaml
import datetime
from pathlib import Path

import pymysql

BASE = Path("/home/vboxuser/py_learn/etl_project")
DB = dict(host="127.0.0.1", port=3306, user="root", password="123456",
          database="dw_project", charset="utf8mb4")


def run_rule(rule):
    """执行一条规则，返回 (实际值, 是否通过)"""
    conn = pymysql.connect(**DB)
    try:
        with conn.cursor() as cur:
            cur.execute(rule["sql"])
            value = cur.fetchone()[0] or 0
    finally:
        conn.close()

    # 判定：拿实际值与阈值比较（方向由 op 决定）
    if rule["op"] == "<=":
        ok = value <= rule["threshold"]
    elif rule["op"] == ">=":
        ok = value >= rule["threshold"]
    else:
        ok = False
    return value, ok


def main():
    rules = yaml.safe_load((BASE / "rules_v2.yaml").read_text(encoding="utf-8"))["rules"]
    today = datetime.date.today().isoformat()
    results, alerts = [], []

    for r in rules:
        value, ok = run_rule(r)
        results.append({
            "run_date": today, "rule_id": r["rule_id"], "table": r["table"],
            "level": r["level"], "value": value,
            "threshold": r["threshold"], "status": "PASS" if ok else "FAIL",
        })
        if not ok:
            alerts.append(f"[{today}][{r['level']}] {r['rule_id']} {r['table']} "
                          f"actual={value} {r['op']} threshold={r['threshold']}")

    # 结果落文件（生产落质量结果表，供大盘读取）
    (BASE / "quality_results.json").write_text(
        json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")

    # 告警追加（空列表不写，避免空文件污染）
    if alerts:
        with open(BASE / "alerts.log", "a", encoding="utf-8") as f:
            f.write("\n".join(alerts) + "\n")


if __name__ == "__main__":
    main()
