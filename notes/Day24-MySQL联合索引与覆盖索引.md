# Day24 · MySQL 联合索引与覆盖索引（最左前缀 / 范围截断 / 排序优化）

> 阶段01 · 第2月 | 配套脚本见 `scripts/day24/` 目录，虚拟机实测通过。
> 背景：联合索引最左前缀原则是索引优化最常考的点，本文全部 explain 实测验证。

---

## 1. 联合索引概念

```sql
CREATE INDEX idx_a_b_c ON test(a,b,c);
```
索引 B+ 树排序规则：**先按 a 排序；a 相同按 b；b 相同按 c**。

## 2. 最左前缀原则（核心）

索引 `idx_a_b_c(a,b,c)`，从最左字段连续匹配，一旦遇到范围查询，后续字段失效。

**✅ 走索引**：
- `where a=1`
- `where a=1 and b=2`
- `where a=1 and b=2 and c=3`
- `where a=1 and b>2 and c=3` → a、b 走索引，c 失效（b 是范围）

**❌ 不走索引**（跳过最左字段）：
- `where b=2` / `where b=2 and c=3` / `where c=3`

> ⚠️ where 条件顺序不影响命中，优化器自动调整；`where b=2 and a=1` 等价 `where a=1 and b=2`。

## 3. 实操对比（explain 实测）

| SQL | type | 说明 |
|-----|------|------|
| `where a=1 and b=2` | ref, Using index | 命中联合索引，等值+覆盖 |
| `where b=2` | index, Using where | 索引全扫描（遍历索引树），缺最左字段，接近全表 |
| `where a=1 and b>2 and c=3` | range | a、b 走索引，c 被范围截断失效 |

**区分关键**：
- `ref / range`：索引快速检索 ✅
- `index`：遍历整个索引树 ❌（只读索引文件，不做快速定位）

## 4. 排序优化（order by 与索引有序性）

索引 `idx_a_b_c(a,b,c)`：
- `where a=1 order by b`：**无 filesort**。a 等值固定，索引内 b 天然有序，直接读取。
- `where a=1 order by c`：**有 filesort**。a 固定后数据按 b 排序，c 并非连续有序，需额外排序。

> ✅ 面试一句话：联合索引有序性是**整体连续有序**，不是每个字段单独有序；order by 字段要紧跟等值字段才不 filesort。

## 5. 联合索引字段顺序选择（两大原则）

1. **等值字段放前面，范围字段放后面**：范围条件后字段失效
2. **区分度高（选择性好）的字段优先放前面**：不同值越多，筛选后数据越少

> 一句话：等值优先，范围靠后；高选择性放前面。

---

## 今日面试考点清单
1. 最左前缀原则？→ 从左连续匹配，范围截断后续失效
2. `where a=1 and c=2` 命中？→ 只有 a，c 跳过 b 失效
3. `where a=1 order by b` filesort？→ 否，a 等值 b 天然有序
4. `where a=1 order by c` filesort？→ 是，c 不连续有序
5. 联合索引顺序选择原则？→ 等值在前范围在后；高选择性在前
6. type=index 与 ref/range 区别？→ 索引遍历 vs 索引检索
7. where 条件顺序影响命中吗？→ 不影响，优化器调整

## 踩坑记录（面试素材）
- 以为 where 顺序影响索引 → 优化器自动调整，看字段不看过顺序
- 跳过中间字段以为还能用 → 最左连续匹配断裂，失效
- 范围截断：b>2 后以为 c 还走索引 → 范围后全部失效
- order by 字段没紧跟等值字段 → 触发 filesort
- type=index 当命中索引 → 是遍历索引树，接近全表
