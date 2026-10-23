# Day65 · 数据治理：质量平台化与安全（规则配置化 + 脱敏 + RBAC）

> 模块五 · 大数据数仓进阶 Day10（加量版）| 配套脚本见 `scripts/day65/`。
> 真实环境：quality_check.py（Day51）升级为规则配置化引擎，脱敏函数与权限矩阵落地。

---

## 1. 质量平台 vs 脚本校验（面试必答）

| | 脚本校验（Day51） | 质量平台（规则配置化） |
|--|-------------------|------------------------|
| 规则位置 | 写死在代码 if 里 | **配置文件**（rules.yaml） |
| 加规则 | 改代码+重新发布 | **改配置，代码不动** |
| 扩展 | 每加规则加一段代码 | 引擎通用，规则即数据 |

> 面试一句话：质量平台 = 规则配置化 + 统一调度 + 告警 + 工单闭环；脚本是"写死"，平台是"配出来"。

## 2. 实操①：rules.yaml + quality_engine.py

```yaml
# rules.yaml（规则配置，改规则只改这里）
rules:
  - {table: dwd_order_detail, column: order_id, rule: unique,        threshold: 0}
  - {table: dwd_order_detail, column: amount,   rule: non_negative,  threshold: 0}
  - {table: dwd_order_detail, column: amount,   rule: not_null_rate, threshold: 0.99}
  - {table: ods_order,        column: order_id, rule: unique,        threshold: 0}
  - {table: ads_gmv_report,   column: gmv,      rule: non_negative,  threshold: 0}
```

quality_engine.py：读 rules.yaml → 逐条执行（unique / non_negative / not_null_rate）→ 输出 PASS/FAIL → exit code。

### 踩坑实录
- **amount 错配 unique**：金额本身会重复（9单6个不同金额）→ FAIL → 改配置（unique 移到 order_id）→ 全 PASS，代码没动
- **pip 装 pyyaml 报 PEP 668**（externally-managed-environment）→ 正确解法 `sudo apt install python3-yaml`

## 3. 数据安全分级 + 脱敏（实操②）

### 分级（4级）
```text
公开（商品名）→ 一般（订单号/金额）→ 敏感（手机号/身份证/姓名）→ 极敏感（银行卡）
越敏感 → 加密/脱敏/权限越严
```

### 脱敏（Masking）
保留格式、打码内容：`13812345678 → 138****5678`、`张三丰 → 张*`、`360101199901011234 → 360101********1234`

> **脱敏不可逆（打码还原不了）vs 加密可逆（有密钥还原）**——核心区别。

## 4. RBAC 权限模型 + 实操③权限矩阵

```text
用户 → 角色 → 权限
用户不直接配权限，配角色；角色绑权限
→ 加人/调岗只改角色，不逐个配权限
```

### 权限矩阵（4角色）
| 角色 | ods_order | dwd_order_detail | dws_* | ads_gmv_report | dim_user（含手机号） |
|------|-----------|------------------|-------|----------------|----------------------|
| 数据开发 | 读写 | 读写 | 读写 | 读写 | 读写（脱敏后） |
| 数仓管理员 | 读写 | 读写 | 读写 | 读写 | 读写（明文） |
| 报表用户 | 只读 | 只读 | 只读 | 只读 | 只读（脱敏后） |
| 业务方 | 不可见 | 不可见 | 只读 | 只读 | 不可见 |

> 敏感表普通角色只给脱敏后读，防止核心信息泄露。

---

## 今日面试考点清单
1. 平台 vs 脚本？→ 规则配置化 vs 写死
2. 加规则改什么？→ rules.yaml，代码不动
3. 数据安全分级？→ 4级：公开/一般/敏感/极敏感
4. 脱敏 vs 加密？→ 不可逆 vs 可逆（密钥）
5. RBAC？→ 用户→角色→权限；敏感表脱敏后读

## 易混淆坑
- amount 配 unique 是错配（金额天然重复），unique 给主键
- 脱敏≠加密（不可逆 vs 可逆）
- PEP 668 环境 pip 装包要 apt 装打包版本
- 权限矩阵里"读写"≠所有表，敏感表另设脱敏策略
