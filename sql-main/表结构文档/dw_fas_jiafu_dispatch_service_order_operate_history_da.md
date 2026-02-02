# dw_fas_jiafu_dispatch_service_order_operate_history_da

## 表基本信息

- **数据库名**: `dw`
- **表名**: `dw_fas_jiafu_dispatch_service_order_operate_history_da`
- **中文名**: 服务单操作记录表
dw_fas_jiafu_dispatch_service_order_operate_history_da
- **表说明**: 加服派单服务单操作历史表（天表）
- **更新日期**: 2026-01-15

---

## 字段信息

| 序号 | 字段名 | 数据类型 | 是否允许NULL | 默认值 | 字段说明 |
|------|--------|----------|--------------|--------|----------|
| 1 | id | BIGINT | YES | NULL | 主键ID |
| 2 | service_order_code | STRING | YES | NULL | 服务单号 |
| 3 | operate_type | STRING | YES | NULL | 操作类型 |
| 4 | operate_time | TIMESTAMP | YES | NULL | 操作时间 |
| 5 | operator_name | STRING | YES | NULL | 操作人姓名 |
| 6 | operator_id | BIGINT | YES | NULL | 操作人ID |
| 7 | operate_content | STRING | YES | NULL | 操作内容 |
| 8 | create_time | TIMESTAMP | YES | NULL | 创建时间 |
| 9 | update_time | TIMESTAMP | YES | NULL | 更新时间 |
| 10 | pt | STRING | NO | NULL | 分区字段（日期） |

---

## 分区信息

- **分区字段**: `pt` (STRING)
- **分区类型**: 按日期分区（格式：YYYY-MM-DD）
- **分区示例**: `pt='2026-01-15'`

---

## 索引信息

暂无

---

## 存储信息

- **存储格式**: ORC
- **压缩方式**: SNAPPY

---

## 备注

- 该表记录加服派单服务单的所有操作历史记录
- 用于追踪服务单的操作轨迹和状态变更
- 按天分区存储，便于历史数据查询和管理

### 常用查询示例

```sql
-- 查询某个服务单的操作历史
SELECT 
    service_order_code,
    operate_type,
    operate_time,
    operator_name,
    operate_content
FROM dw_fas_jiafu_dispatch_service_order_operate_history_da
WHERE service_order_code = 'xxxxx'
    AND pt >= '2026-01-01'
ORDER BY operate_time DESC;
```

### 关联表说明

- 关联表：`rpt_fas_jiafu_dispatch_service_order_product_da` - 加服派单服务单商品表
- 关联字段：`service_order_code` - 服务单号

---

## 建表语句

```sql
-- 请在此处补充建表语句
CREATE TABLE IF NOT EXISTS dw_fas_jiafu_dispatch_service_order_operate_history_da (
    id BIGINT COMMENT '主键ID',
    service_order_code STRING COMMENT '服务单号',
    operate_type STRING COMMENT '操作类型',
    operate_time TIMESTAMP COMMENT '操作时间',
    operator_name STRING COMMENT '操作人姓名',
    operator_id BIGINT COMMENT '操作人ID',
    operate_content STRING COMMENT '操作内容',
    create_time TIMESTAMP COMMENT '创建时间',
    update_time TIMESTAMP COMMENT '更新时间'
)
COMMENT '加服派单服务单操作历史表'
PARTITIONED BY (pt STRING COMMENT '日期分区')
STORED AS ORC;
```
