# ===== etl_main.py：入口层（编排流程，只做调用）=====
from config import INPUT_FILE
from etl_utils import extract, transform, load

if __name__ == "__main__":
    print("=== ETL 开始 ===")
    df = extract(INPUT_FILE)   # E
    df = transform(df)         # T
    load(df)                   # L
    print("=== ETL 完成 ===")
