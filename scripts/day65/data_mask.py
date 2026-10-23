# Day65 实操②：敏感字段脱敏函数（保留格式、打码内容，不可逆）
# 用法：python3 data_mask.py

def mask_phone(phone):
    """手机号：138****5678（留前3后4）"""
    return phone[:3] + "****" + phone[7:]


def mask_name(name):
    """姓名：张*（留姓）"""
    return name[0] + "*"


def mask_idcard(idcard):
    """身份证：360101********1234（留前6后4）"""
    return idcard[:6] + "**********" + idcard[-4:]


if __name__ == "__main__":
    print(mask_phone("13812345678"))
    print(mask_name("张三丰"))
    print(mask_idcard("360101199901011234"))
