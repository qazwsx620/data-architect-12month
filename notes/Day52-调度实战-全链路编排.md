# Day52 · 数仓项目·调度实战：全链路编排（主控脚本 + crontab + 重跑）

> 模块四 · 数仓工程 Day9（加量版：4个实操）| 配套脚本见 `scripts/day52/`（etl_chain.py + rerun.sh）。
> 背景：把 Day47-51 各层脚本串成完整自动化链路，Day45 的 Airflow DAG 概念落地到 crontab 实现。

---

## 1. 全链路编排（Airflow DAG 落地）

Day45 设计 DAG：`extract_ods → transform_dwd → aggregate_dws → report_ads`，今天用主控脚本实现同样依赖：

```text
extract_ods（Day47） → transform_dwd（Day48） → aggregate_dws（Day49 SQL）
    → report_ads（Day50 SQL+导出） → quality_check（Day51）
```

**核心原则：上游失败立即退出，下游不执行（依赖阻断）。**

## 2. 主控脚本 etl_chain.py 核心

```python
def run_step(name, cmd):
    """执行一个步骤；失败立即退出（下游阻断）"""
    print(f"\n===== {name} =====")
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        print(f"❌ {name} 失败（exit={result.returncode}），终止链路，下游不执行")
        sys.exit(1)
    print(f"✅ {name} 成功")

steps = [
    ("ODS抽取",   "python3 ods_extract.py"),
    ("DWD清洗",   "python3 dwd_transform.py"),
    ("DWS汇总",   "mysql ... dw_project < dws_aggregate.sql"),
    ("ADS报表",   "mysql ... dw_project < ads_report.sql"),
    ("报表导出",  "python3 ads_export.py && python3 ads_report_html.py"),
    ("质量校验",  "python3 quality_check.py"),
]
```

> `subprocess.run(cmd).returncode` 拿到子进程 exit code，非 0 = 失败。

## 3. crontab 落地

```bash
echo "0 2 * * * cd /home/vboxuser/py_learn/etl_project && /usr/bin/python3 etl_chain.py >> etl_chain.log 2>&1" | crontab -
crontab -l   # 验证
```
> **crontab 本身不支持失败自动重试**：生产上脚本内循环重试 / 交给 Airflow retries。

## 4. 一键重跑（幂等是前提）

- 各层加载均幂等（DWD 先删后插、DWS/ADS TRUNCATE 重算）
- **重跑 = 再执行一次 etl_chain.py，结果完全一致**
- rerun.sh 包装一键执行

```bash
diff run1.csv ads_gmv_report.csv   # ✅ 两次结果完全一致（幂等验证通过）
```

## 5. 运行验证结果（完整链路）

| 步骤 | 结果 |
|------|------|
| ODS抽取 | 增量 0 行（水位线 10-13）✅ |
| DWD清洗 | 9 行 ✅ |
| DWS汇总 / ADS报表 | 成功 ✅ |
| 报表导出 | CSV 4 行 + HTML ✅ |
| 质量校验 | 5 条全 PASS ✅ |
| 链路 exit | 0 ✅ |
| 幂等重跑 | diff 一致 ✅ |

## 6. 脏数据传导实战（Day51 遗留 -50）

- DWD 残留 order_id=39999 amount=-50（Day51 测试数据未清理）
- 传染链：**DWD FAIL → DWS FAIL（被汇总）→ ADS FAIL（再聚合）**
- 质量校验最后一层兜住，链路 exit=1 终止
- 清理脏数据源后全链路恢复 ✅

> 面试素材：一条脏数据逐层传导污染整个链路——逐层校验的必要性 + 血缘排查的价值。

---

## 今日面试考点清单
1. 编排核心原则？→ 上游失败立即退出，下游阻断
2. returncode？→ subprocess.run().returncode 判失败
3. crontab 能重试吗？→ 不能；脚本内重试 / Airflow retries
4. 一键重跑前提？→ 幂等（重复执行结果一致）
5. 脏数据传导说明什么？→ 逐层校验必要性 + 血缘排查价值

## 踩坑记录（面试素材）
- SQL 文件缺失 → 第3步失败，链路终止（失败阻断生效）
- crontab 无重试机制 → 需脚本内重试或调度框架
- 不幂等 → 重跑数据翻倍
- 脏数据不清理 → 逐层传染，最终报表错
