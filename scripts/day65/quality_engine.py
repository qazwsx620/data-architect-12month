# Day65 实操①：规则配置化校验引擎（规则不再写死，读 rules.yaml 执行）
# 依赖：python3-yaml（sudo apt install python3-yaml）
# 用法：python3 quality_engine.py; echo "exit=$?"

import sys
import pymysql
import yaml

CONFIG = {"host": "localhost", "user": "root", "password": "123456", "database": "dw_project"}


def load_rules(path="rules.yaml"):
    with open(path) as f:
        return yaml.safe_load(f)["rules"]


def run_check(conn, rule):
    table, col, kind = rule["table"], rule["column"], rule["rule"]
    cur = conn.cursor()
    if kind == "unique":
        cur.execute(f"SELECT COUNT(*), COUNT(DISTINCT {col}) FROM {table}")
        c1, c2 = cur.fetchone()
        return c1 == c2, f"{table}.{col} 唯一性(总{c1}/去重{c2})"
    if kind == "non_negative":
        cur.execute(f"SELECT COUNT(*) FROM {table} WHERE {col} < 0")
        bad = cur.fetchone()[0]
        return bad <= rule.get("threshold", 0), f"{table}.{col} 非负(异常{bad})"
    if kind == "not_null_rate":
        cur.execute(f"SELECT COUNT(*), SUM({col} IS NULL) FROM {table}")
        total, nulls = cur.fetchone()
        rate = 1 - (nulls / total if total else 1)
        return rate >= rule.get("threshold", 0.99), f"{table}.{col} 非空率({rate:.2%})"
    return False, "未知规则"


def main():
    conn = pymysql.connect(**CONFIG)
    rules = load_rules()
    failed = 0
    for r in rules:
        ok, msg = run_check(conn, r)
        print(f"[{'PASS' if ok else 'FAIL'}] {msg}")
        failed += 0 if ok else 1
    print(" 全部校验通过" if failed == 0 else f" 质量存在问题！({failed}条)")
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
