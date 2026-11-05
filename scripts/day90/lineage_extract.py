# Day90 实操：用 sqlglot 自动解析 SQL 生成表级血缘（虚拟机实测通过）
# 输入：etl_project 下的 *.sql 文件
# 输出：每条 INSERT/CREATE AS 的 source -> target 表级血缘边 + mermaid 图
# 实测：3 条边（dws_aggregate.sql 2 条、ads_report.sql 1 条）

import glob
import sqlglot
from sqlglot import exp

PROJECT_DIR = "/home/vboxuser/py_learn/etl_project"


def extract_from_sql(sql_text, dialect="mysql"):
    """解析一段 SQL，返回 [(source, target)] 表级血缘边"""
    edges = []
    for stmt in sqlglot.parse(sql_text, dialect=dialect):
        if stmt is None:
            continue
        # 找写入目标：INSERT INTO / CREATE TABLE AS
        if isinstance(stmt, exp.Insert):
            target = stmt.this.find(exp.Table)
        elif isinstance(stmt, exp.Create):
            target = stmt.this.find(exp.Table)
        else:
            continue
        if target is None:
            continue
        # 找所有来源表（排除目标表自身）
        for tbl in stmt.find_all(exp.Table):
            if tbl is target:
                continue
            edges.append((tbl.name, target.name))
    return edges


def main():
    all_edges = set()
    for f in glob.glob(f"{PROJECT_DIR}/*.sql"):
        print(f"\n===== {f} =====")
        with open(f, encoding="utf-8") as fp:
            edges = extract_from_sql(fp.read())
        for src, tgt in edges:
            print(f"{src} --> {tgt}")
            all_edges.add((src, tgt))
    print(f"\n共 {len(all_edges)} 条表级血缘边")

    # 输出 mermaid 血缘图
    print("\n```mermaid")
    print("graph LR")
    for src, tgt in all_edges:
        print(f"    {src} --> {tgt}")
    print("```")


if __name__ == "__main__":
    main()
