# 服务单签到异常反馈表

## 表基本信息

- **数据库名**: `ods`
- **表名**: `ods_plat_jiafu_dispatch_service_order_sign_in_feedback_di`
- **表中文名**: 服务单签到异常反馈表
- **表说明**: 记录服务单签到异常反馈的相关信息
- **更新日期**: 2026-01-13

---

## 字段信息

| 序号 | 字段名 | 数据类型 | 是否允许NULL | 默认值 | 字段说明 |
|------|--------|----------|--------------|--------|----------|
| 1 | id | BIGINT | NO | NULL | 主键ID |
| 2 | service_order_code | STRING | YES | NULL | 服务单编码 |
| 3 | sign_in_feedback_type | STRING | YES | NULL | 签到反馈类型 |
| 4 | feedback_content | STRING | YES | NULL | 反馈内容 |
| 5 | feedback_time | TIMESTAMP | YES | NULL | 反馈时间 |
| 6 | create_time | TIMESTAMP | YES | NULL | 创建时间 |
| 7 | update_time | TIMESTAMP | YES | NULL | 更新时间 |
| 8 | pt | STRING | NO | NULL | 分区字段 |

---

## 分区信息

- **分区字段**: `pt` (STRING)
- **分区类型**: 按日期分区（格式：YYYY-MM-DD）
- **分区示例**: `pt='2026-01-13'`

---

## 索引信息

[待完善]

---

## 存储信息

[待完善]

---

## 备注

- 本表用于记录服务单签到过程中的异常反馈信息
- 常用于异常签到分析和统计
- 相关表：
  - `rpt_rpt_weixiu_abnormal_checkin_list` - 维修异常签到列表
  - `异常签到.sql` - 异常签到查询
  - `异常签到平铺.sql` - 异常签到平铺查询

---

## 建表语句

```sql
-- 待补充 SHOW CREATE TABLE 的输出结果
```

---

## 使用示例

```sql
-- 查询最近7天的签到异常反馈
SELECT 
    service_order_code,
    sign_in_feedback_type,
    feedback_content,
    feedback_time
FROM ods_plat_jiafu_dispatch_service_order_sign_in_feedback_di
WHERE pt >= DATE_SUB(CURRENT_DATE(), 7)
ORDER BY feedback_time DESC;
```
