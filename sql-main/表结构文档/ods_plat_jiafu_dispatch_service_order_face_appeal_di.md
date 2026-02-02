# 表结构文档 - ods_plat_jiafu_dispatch_service_order_face_appeal_di

## 表基本信息

- **数据库名**: `ods`
- **表名**: `ods_plat_jiafu_dispatch_service_order_face_appeal_di`
- **表说明**: 服务单人脸识别申诉表
- **更新日期**: 2026-01-13

---

## 字段信息

| 序号 | 字段名 | 数据类型 | 是否允许NULL | 默认值 | 字段说明 |
|------|--------|----------|--------------|--------|----------|
| 1 | id | BIGINT | NO | NULL | 主键ID |
| 2 | service_order_code | STRING | YES | NULL | 服务单编码 |
| 3 | appeal_type | INT | YES | NULL | 申诉类型 |
| 4 | appeal_reason | STRING | YES | NULL | 申诉原因 |
| 5 | appeal_status | INT | YES | NULL | 申诉状态 |
| 6 | appeal_time | TIMESTAMP | YES | NULL | 申诉时间 |
| 7 | appeal_user_id | BIGINT | YES | NULL | 申诉人ID |
| 8 | appeal_user_name | STRING | YES | NULL | 申诉人姓名 |
| 9 | handle_time | TIMESTAMP | YES | NULL | 处理时间 |
| 10 | handle_user_id | BIGINT | YES | NULL | 处理人ID |
| 11 | handle_user_name | STRING | YES | NULL | 处理人姓名 |
| 12 | handle_result | STRING | YES | NULL | 处理结果 |
| 13 | remark | STRING | YES | NULL | 备注 |
| 14 | create_time | TIMESTAMP | YES | NULL | 创建时间 |
| 15 | update_time | TIMESTAMP | YES | NULL | 更新时间 |
| 16 | pt | STRING | NO | NULL | 分区字段 |

---

## 分区信息

- **分区字段**: `pt` (STRING)
- **分区类型**: 按日期分区（格式：YYYY-MM-DD）
- **分区示例**: `pt='2026-01-13'`

---

## 索引信息

[如有索引，在此填写]

---

## 存储信息

- **存储格式**: [ORC/Parquet等]
- **压缩方式**: [如有，在此填写]

---

## 备注

- 该表记录家服派单服务单面销申诉的相关信息
- 用于跟踪服务单的申诉流程和处理结果
- [其他说明信息]

---

## 常用查询示例

```sql
-- 查询最近一天的申诉记录
SELECT *
FROM ods_plat_jiafu_dispatch_service_order_face_appeal_di
WHERE pt = '${date}'
LIMIT 100;

-- 按申诉状态统计
SELECT 
    appeal_status,
    COUNT(*) as cnt
FROM ods_plat_jiafu_dispatch_service_order_face_appeal_di
WHERE pt = '${date}'
GROUP BY appeal_status;
```

---

## 建表语句

```sql
-- 在此粘贴 SHOW CREATE TABLE 的输出结果
CREATE TABLE IF NOT EXISTS ods_plat_jiafu_dispatch_service_order_face_appeal_di (
    -- 字段定义
)
PARTITIONED BY (pt STRING)
STORED AS ORC;
```

---

## 相关表说明

- 关联表1: [如有，在此填写]
- 关联表2: [如有，在此填写]
