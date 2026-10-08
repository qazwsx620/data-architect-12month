#!/usr/bin/env python3
# Day35 演示：Python 基础（数据结构/函数/文件读写/异常处理/CSV统计）
# 用法：python3 data_struct.py / functions.py / file_demo.py / csv_stat.py

# ====== data_struct.py：四大数据结构 ======
amounts = [99, 199, 299, 59, 399]
print("列表长度:", len(amounts))
print("最大金额:", max(amounts))

user = {"name": "张三", "age": 20, "city": "南昌"}
print("姓名:", user["name"])
print("邮箱:", user.get("email", "未填写"))

point = (10, 20)
print("坐标:", point)

status = [1, 1, 2, 1, 3]
print("状态去重:", set(status))

# ====== functions.py：函数与参数 ======
def greet(name, greeting="你好"):
    return f"{greeting}, {name}!"

def calc_sum(*nums):
    return sum(nums)

def show_info(**info):
    for k, v in info.items():
        print(f"{k}={v}")

print(greet("张三"))
print(greet("李四", "Hello"))
print("求和:", calc_sum(1, 2, 3, 4, 5))
show_info(name="王五", age=22, city="上海")

# ====== file_demo.py：文件读写 ======
with open("demo_data.txt", "w", encoding="utf-8") as f:
    f.write("10001,2026-10-01,99\n")
    f.write("10002,2026-10-01,199\n")
    f.write("10003,2026-10-02,299\n")

with open("demo_data.txt", "r", encoding="utf-8") as f:
    lines = f.readlines()
for line in lines:
    print(line.strip())

# ====== csv_stat.py：CSV 读取统计 ======
total = 0
count = 0
try:
    with open("demo_data.txt", "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split(",")
            amount = float(parts[2])
            total += amount
            count += 1
    print(f"共 {count} 条订单")
    print(f"总金额: {total}")
    print(f"平均金额: {total / count:.2f}")
except FileNotFoundError:
    print("文件不存在，请先运行 file_demo.py 生成数据")
except Exception as e:
    print("处理出错:", e)
