# Day58 实操③：小文件问题模拟（100 小文件 vs 1 大文件的 Map 数）
# 1 文件 = 1 Map 任务；小文件多 → Map 启动开销大 + NameNode 压力 + IO 退化

mkdir -p /tmp/hive_small && cd /tmp/hive_small
for i in $(seq 1 100); do echo "order$i,1001,99.00" > part_$i.csv; done
echo "小文件数量(≈Map任务数):"
ls part_*.csv | wc -l

# 合并成 1 个大文件
cat part_*.csv > all_parts.csv
rm part_*.csv
echo "合并后文件(≈Map任务数):"
ls -lh all_parts.csv
