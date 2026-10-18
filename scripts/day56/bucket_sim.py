# Day56 实操③：模拟 Hive 哈希分桶（同键同桶验证）
# 8 条订单按 user_id%4 分 4 桶，观察分布：同一 user_id 永远落同一桶

import os
os.makedirs('/tmp/order_bucket', exist_ok=True)
for i in range(4):
    open(f'/tmp/order_bucket/bucket_{i}', 'w').close()

orders = [(30001,1001),(30002,1002),(30003,1003),(30004,1001),
          (30005,1004),(30006,1005),(30007,1002),(30008,1006)]
for order_id, user_id in orders:
    b = user_id % 4          # 模拟 hash(user_id) % 4
    with open(f'/tmp/order_bucket/bucket_{b}', 'a') as f:
        f.write(f'{order_id},user={user_id}\n')

for i in range(4):
    lines = open(f'/tmp/order_bucket/bucket_{i}').read().strip().split('\n')
    print(f'bucket_{i}: {len([l for l in lines if l])} 条 -> {[l for l in lines if l]}')
