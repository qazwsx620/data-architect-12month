# Day44 · Python 进阶：面向对象与模块化（class / 导入 / 工程结构）

> 模块四 · 数仓工程 Day1 | 配套脚本见 `scripts/day44/` 目录，虚拟机实测通过。
> 背景：把 Day42 单文件 ETL 改造成标准工程结构，是工程化第一步。

---

## 1. 类与对象（class / __init__ / self）

```python
class EtlJob:
    """ETL作业类"""

    def __init__(self, input_path, db_config):
        """构造方法：创建对象时自动调用，初始化属性"""
        self.input_path = input_path
        self.db_config = db_config

    def extract(self):
        print(f"[E] 抽取: {self.input_path}")

    def run(self):
        self.extract()
        self.transform()
        self.load()

job1 = EtlJob("input/orders.csv", {"database": "test_db"})
job1.run()
```
> 关键点：
> - `__init__`：构造方法，创建对象时**自动执行**
> - `self`：代表对象自己
> - `self.xxx`：实例属性，属于具体对象
> - 方法第一个参数永远是 `self`

## 2. 模块导入

```python
import etl_utils                      # 导入整个模块 → etl_utils.函数()
from etl_utils import EtlJob          # 导入具体类 → 直接调用
import pandas as pd                   # 起别名
```
> 面试：`import 模块` 需带模块名前缀；`from 模块 import 东西` 直接调用更简洁；避免 `from x import *`（污染命名空间）。

## 3. 标准工程目录结构（三层分离）

```
etl_project/
├── config.py          # 配置层：路径、数据库连接（改配置不动代码）
├── etl_utils.py       # 逻辑层：抽取/清洗/加载函数
├── etl_main.py        # 入口层：编排流程，只做调用
└── input/             # 输入数据
```

| 层 | 文件 | 职责 |
|----|------|------|
| 配置层 | config.py | 路径、连接参数 |
| 逻辑层 | etl_utils.py | E/T/L 具体实现 |
| 入口层 | etl_main.py | 编排流程 |

> 好处：配置独立（改环境只改 config）、逻辑复用（清洗函数到处可用）、入口清晰（一眼看到流程）。

## 4. 模块化 ETL 改造（Day42 单文件 → 三层）

### config.py
```python
INPUT_FILE = "input/orders.csv"
DB_CONFIG = {
    "host": "127.0.0.1", "user": "root",
    "password": "123456", "database": "test_db",
    "charset": "utf8mb4",
}
```

### etl_utils.py
```python
import pandas as pd
import pymysql
from config import DB_CONFIG

def extract(input_file):
    return pd.read_csv(input_file)

def transform(df):
    df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
    df["create_date"] = pd.to_datetime(df["create_date"], format="mixed").dt.strftime("%Y-%m-%d")
    df = df.drop_duplicates(subset=["order_id"])
    df["status"] = df["status"].fillna(1).astype(int)
    df["amount"] = df["amount"].fillna(0).round(2)
    return df

def load(df, table="etl_orders"):
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()
    cursor.execute(
        f"DELETE FROM {table} WHERE order_id IN (%s)" % ",".join(["%s"] * len(df)),
        df["order_id"].tolist()
    )
    cursor.executemany(
        f"INSERT INTO {table}(order_id, user_id, amount, status, create_date) "
        "VALUES (%s, %s, %s, %s, %s)",
        df[["order_id", "user_id", "amount", "status", "create_date"]].values.tolist()
    )
    conn.commit()
    rows = cursor.rowcount
    conn.close()
    return rows
```

### etl_main.py
```python
from config import INPUT_FILE
from etl_utils import extract, transform, load

if __name__ == "__main__":
    print("=== ETL 开始 ===")
    df = extract(INPUT_FILE)
    df = transform(df)
    load(df)
    print("=== ETL 完成 ===")
```
> 运行结果：`=== ETL 开始 === 写入 5 行 === ETL 完成 ===`

---

## 今日面试考点清单
1. __init__ 作用？self？→ 构造自动执行 / 对象自己
2. 方法与函数区别？→ 方法挂在对象上，第一个参数 self
3. import 两种写法？→ 模块前缀 vs 直接调用
4. 配置独立？→ 改环境只改 config
5. 三层结构？→ 配置/逻辑/入口

## 踩坑记录（面试素材）
- 忘写 self → TypeError，方法第一参数必须是 self
- `from x import *` → 命名空间污染
- 配置写死在函数里 → 换环境改代码，违背工程化
- 入口文件堆逻辑 → 编排与实现不分，难维护
- 单文件脚本越写越长 → 拆三层，配置/逻辑/入口
