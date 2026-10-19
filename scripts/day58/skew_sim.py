# Day58 实操②：数据倾斜模拟（直接聚合 vs 加盐两阶段）
# 验证：直接聚合热点桶 9 万条倾斜；加盐两阶段各桶均衡

import random

# 模拟：user1001 热点（90% 订单），其余 9 用户共 10%
orders = [('user1001',) if random.random() < 0.9 else (f'user{random.randint(1002,1010)}',)
          for _ in range(100000)]


def count_by_reduce(data, n_reduce=5):
    """直接聚合：按 key 哈希分 reduce，统计各 reduce 处理量"""
    buckets = [0] * n_reduce
    for (k,) in data:
        b = hash(k) % n_reduce
        buckets[b] += 1
    return buckets


def salted_count_by_reduce(data, n_reduce=5, salt=10):
    """加盐两阶段：先加随机盐局部聚合，再去盐归并（负载按小计条数）"""
    buckets = [0] * n_reduce
    local = {}
    for (k,) in data:
        salted_key = f"{k}#{random.randint(0, salt - 1)}"   # 加盐拆散
        local[salted_key] = local.get(salted_key, 0) + 1
    # 局部聚合后：每盐桶只贡献 1 条"小计"（不是 cnt！）
    for sk in local:
        real_key = sk.split('#')[0]
        b = hash(real_key) % n_reduce
        buckets[b] += 1
    return buckets


print("直接聚合各Reduce处理量:", count_by_reduce(orders))
print("加盐两阶段各Reduce处理量:", salted_count_by_reduce(orders))
