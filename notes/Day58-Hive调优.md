# Day58 · Hive 调优（数据倾斜 + explain + 小文件 + 资源调整）

> 模块五 · 大数据数仓进阶 Day3（加量版）| 配套脚本见 `scripts/day58/`。
> 环境说明：虚拟机无 Hive，走"原理 + Python/文件系统/MySQL 模拟"路线。

---

## 1. 数据倾斜（面试必问题）

### 是什么
按 key 分到不同 Reduce 处理时，**某个 key 数据量远大于其他 key** → 一个 Reduce 累死、其他闲着 → 任务卡 99%。

### 成因 + 表现
- 成因：key 分布不均（热点用户/商品/城市）、join 关联键大量 null、group by 维度过集中
- 表现：任务停在 99%、某个 Reduce 一直 running、其他已完成

### 解决方案（核心）
| 方案 | 思路 | 适用 |
|------|------|------|
| ① 加盐打散（两阶段聚合） | 随机前缀拆散 → 局部聚合 → 去盐全局聚合 | group by 倾斜 |
| ② 热点 key 单独处理 | 热点拆出来单独算再合并 | 已知热点 |
| ③ 倾斜 join 优化 | 小表广播 / 热点 key 拆分膨胀关联 | join 倾斜 |
| ④ 过滤 null | join 前过滤/单独处理 null | null 集中 |

> 加盐核心原理：**万行原始数据先压成几十条小计，reduce 只数小计**。
> 模拟验证：直接聚合一个桶 91195 条（倾斜）→ 加盐两阶段各桶 10~30 条（均衡）。

## 2. explain 执行计划

| 列 | 看什么 |
|----|--------|
| type | ALL(全表扫) < index < range < ref < eq_ref < const |
| rows | 预估扫描行数（越小越好） |
| Extra | Using where / Using filesort / Using temporary / Using index |
| partitions | 分区裁剪 |

Hive 也有 EXPLAIN：看 stage 划分、join 顺序、map/reduce 阶段。

### 实操模拟结论
- 查询只 join 主键、SELECT 不取数据行 → 覆盖索引（Using index），比全表扫好
- `filtered=11.11%` → where 先过滤约 89% 再 join = **谓词下推生效**

## 3. 谓词下推

**把 WHERE 过滤尽量提前（下推到 map/扫描时），先瘦身再计算**——MySQL/Hive/Spark 优化器自动做。

```text
优化前：先 JOIN 再 WHERE（大表全量参与 join）
优化后：map 端先按条件过滤 → join 数据量骤减
```

## 4. 小文件问题

```text
1 文件 = 1 Map 任务；1000 个小文件 = 启动 1000 个 Map
```
| 危害 | 说明 |
|------|------|
| Map 启动开销 | JVM 启动成本 > 计算成本 |
| NameNode 压力 | 每文件一条元数据，百万小文件吃内存 |
| IO 退化 | 顺序读变随机寻址 |

### 解决
- 合并：`INSERT OVERWRITE` 重写 / 控制 reduce 数（`mapred.reduce.tasks`）
- 自动合并：`hive.merge.mapfiles` / `hive.merge.smallfiles.avgsize`
- 控制源头：分区合理、控制每次写入文件数

### 资源调整
- Map 数 ≈ 输入文件数/分片大小（`mapred.min.split.size` 合并小分片）
- Reduce 数 ≈ 分区数，可设 `mapred.reduce.tasks`（不是越多越好）

> 模拟验证：100 个小文件 = 100 个 Map，合并成 1 个大文件 = 1 个 Map，差 99 个。

---

## 今日面试考点清单
1. 数据倾斜？→ key 不均 + 99% 卡住 + 单 reduce running
2. group by 倾斜解法？→ 加盐两阶段聚合（局部→全局）
3. 加盐为什么均衡？→ 原始行压成小计，reduce 数小计
4. 谓词下推？→ where 下推 map/扫描，优化器自动做
5. 小文件三危害？→ Map 启动开销 + NameNode 内存 + IO 退化
6. 小文件解决？→ 合并 + 控制 reduce 数 + 控制源头

## 易混淆坑
- 加盐两阶段第二阶段按"小计条数"计负载（不是原始行数）
- Reduce 数不是越多越好（有启动开销）
- 谓词下推是优化器自动做的，不是手动写
- 分区（列值/目录级）与分桶（哈希/文件级）别混（Day56）
