# Day35 · Python 基础（数据开发视角：数据结构 / 函数 / 文件读写 / 异常处理）

> 模块三 · Python 阶段 Day1 | 配套脚本见 `scripts/day35/` 目录，虚拟机实测通过。
> 背景：从数据开发视角系统过 Python 基础，为 Pandas/ETL 打底。

---

## 1. 四大核心数据结构（面试高频）

| 结构 | 特点 | 适用 |
|------|------|------|
| 列表 list | 有序、可修改、可重复 | 有序集合、按序处理 |
| 字典 dict | 键值对、键唯一（3.7+有序） | 映射、结构化记录 |
| 元组 tuple | 有序、**不可修改** | 不可变数据、多返回值 |
| 集合 set | 无序、自动去重、唯一 | 去重、交集/并集 |

```python
lst = [1, 2, 3]; lst.append(4)
d = {"name": "张三"}; d.get("email", "无")   # 安全取值
t = (1, 2, 3)                                 # 不可改
s = {1, 2, 2, 3}                              # 自动去重 {1,2,3}
```

## 2. 函数

```python
def greet(name, greeting="你好"):     # 默认参数
    return f"{greeting}, {name}!"

def calc_sum(*nums):                  # *args 位置参数→元组
    return sum(nums)

def show_info(**info):                # **kwargs 关键字参数→字典
    for k, v in info.items():
        print(f"{k}={v}")
```
> 面试：`*args` 收任意位置参数变**元组**；`**kwargs` 收任意键值对变**字典**。

## 3. 文件读写

```python
# with 自动关闭，防止文件句柄泄漏（推荐）
with open("data.txt", "r", encoding="utf-8") as f:
    content = f.read()        # 全读成字符串
    lines = f.readlines()     # 按行读成列表

with open("out.txt", "w", encoding="utf-8") as f:
    f.write("第一行\n")
```
| 模式 | 含义 |
|------|------|
| r | 只读（默认） |
| w | 覆盖写（不存在创建） |
| a | 追加写 |
| r+/w+ | 读写 |

> encoding="utf-8" 避免中文乱码（Windows 默认 GBK）。

## 4. 异常处理

```python
try:
    num = int(input("请输入数字: "))
    print(100 / num)
except ValueError:
    print("输入的不是数字！")
except ZeroDivisionError:
    print("不能除以0！")
except Exception as e:      # 通用兜底，放最后
    print("其他错误:", e)
finally:
    print("无论是否异常都执行")   # 常用于关闭资源
```
> 面试：except 从具体到通用；finally 无条件执行。

## 5. 综合实操：读取 CSV 统计（最简 ETL）

```python
total, count = 0, 0
with open("demo_data.txt", "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line: continue          # 跳过空行
        parts = line.split(",")        # CSV 按逗号拆分
        total += float(parts[2])       # 第3列是金额
        count += 1
print(f"共 {count} 条订单，总金额: {total}，平均: {total/count:.2f}")
```
> 输出：共 3 条订单，总金额 597.0，平均 199.00
> split(",") 必须指定逗号：split() 默认按空白拆分。

---

## 今日面试考点清单
1. 四大数据结构特点？→ 列表可改、元组不可改、字典键唯一、集合去重
2. *args/**kwargs？→ 位置参数变元组 / 关键字参数变字典
3. with open 作用？→ 自动关闭，防句柄泄漏
4. try/except/finally？→ 执行/捕获处理/无条件执行
5. split(",") 为什么指定逗号？→ CSV 逗号分隔，默认按空白
6. encoding="utf-8"？→ 防中文乱码

## 踩坑记录（面试素材）
- 元组试图修改 → TypeError，不可变
- split() 不带参数处理 CSV → 按空白拆不出逗号列
- 忘 encoding="utf-8" → 中文乱码
- 文件用完不关 → 句柄泄漏；用 with
- except 顺序：具体异常在前，Exception 兜底在后
