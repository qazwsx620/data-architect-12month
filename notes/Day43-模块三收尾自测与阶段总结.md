# Day43 · 模块三收尾自测与阶段总结（SQL进阶 / Python-Pandas / Git / 数仓基础 / ETL实战）

> 模块三（Day32-43）收官 | 本模块产出一个完整可运行 ETL 项目（scripts/day42/）。
> 背景：数据开发方向基础能力搭建完成，下一阶段进入模块四"数仓工程与数据管道"。

---

## 1. 模块三知识全景

| 阶段 | 天数 | 核心能力 |
|------|------|----------|
| SQL 进阶 | Day32-34 | 聚合/窗口函数/子查询/CTE |
| Python+Pandas | Day35-38 | 语法基础/数据清洗/分组聚合 |
| Git | Day39 | 分支/冲突/回退 |
| 数仓基础 | Day40-42 | 分层建模/Hive/ETL实战 |
| 收尾自测 | Day43 | 全链路口述+动手题 |

## 2. 收尾自测记录（10题：9对 + 1纠正）

**批次1（口述6题）**：
- ✔ 分组TopN（ROW_NUMBER+CTE+外层过滤）
- ✔ IN/EXISTS（先查结果集 vs 逐行比对；8.0 改写 semi join）
- ❌→✔ SQL 执行顺序（纠正：**FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY**，锚点"FROM 最先，SELECT 后显"）
- ✔ Pandas↔SQL 对照 7 组
- ✔ 数仓四层职责+流向
- ✔ ETL 三环节+幂等+质量四要素

**批次2（动手4题）**：全部一次答对
- ✔ GROUP BY+HAVING 统计（cnt>=2）
- ✔ RANK() 窗口函数 Top1（并列最高都返回）
- ✔ groupby.agg 分组聚合
- ✔ Git 冲突解决三步（改文件→add→commit）

## 3. 模块三面试题清单（全部可复述）

### SQL 进阶
1. 聚合函数？COUNT(*) vs COUNT(字段)？
2. WHERE vs HAVING？SQL 执行顺序？
3. 窗口函数 vs GROUP BY？三个排名函数区别？
4. 分组 TopN 标准解法？
5. IN vs EXISTS？MySQL 8.0 优化？
6. CTE 优点？

### Python/Pandas
7. 四大数据结构特点？*args/**kwargs？
8. with open 作用？try/except/finally？
9. loc vs iloc？describe() 统计量？
10. 清洗四步流程？为什么先类型转换再去重？
11. Pandas↔SQL 对照（WHERE/GROUP BY/JOIN/UNION ALL/LIMIT）？

### Git
12. 分支本质？空分支为什么无效引用？
13. 冲突条件与解决三步？reset 三级？

### 数仓/ETL
14. 四层职责+流向？为什么要分层？
15. 事实表 vs 维度表？粒度？星型 vs 雪花？SCD？事实表分类？
16. Hive vs MySQL？分区表作用？内外部表？
17. ETL 流程口述？幂等？数据质量四要素？
18. pymysql 占位符正确用法？

## 4. 交付物
- notes/Day32-43 全部入库
- scripts/day32-42 全部入库（含 Day42 完整 ETL 项目：etl.py + etl_init.sql + input/orders.csv）
- 计划表：模块三（Day32-43）✅ 完成，模块四（Day44-56）已规划

## 5. 自测暴露的薄弱点
- SQL 执行顺序开头易漏 FROM → 已用锚点"FROM 最先，SELECT 后显"强化
- 其余考点均一次答对，可进入模块四
