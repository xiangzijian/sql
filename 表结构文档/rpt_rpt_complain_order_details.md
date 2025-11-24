# 表结构：rpt.rpt_complain_order_details

## 表基本信息

- **数据库名**: `rpt`
- **表名**: `rpt_complain_order_details`
- **表说明**: 投诉订单明细表
- **更新日期**: [待更新]

---

## 字段信息

> ⚠️ **注意**: 以下字段信息基于SQL使用情况提取，完整字段列表请通过 `DESC` 或 `SHOW CREATE TABLE` 命令获取

| 序号 | 字段名 | 数据类型 | 是否允许NULL | 默认值 | 字段说明 |
|------|--------|----------|--------------|--------|----------|
| 1 | date_stamp | STRING | YES | NULL | 日期戳（格式：YYYY-MM-DD） |
| 2 | city_name | STRING | YES | NULL | 城市名称 |
| 3 | ticket_description | STRING | YES | NULL | 工单描述 |
| 4 | order_no | STRING | YES | NULL | 订单号 |
| 5 | beiyong2 | STRING | YES | NULL | 备用字段2（包含距离信息，格式：直线距离:X.XXkm） |

---

## 分区信息

- **分区字段**: `pt` (STRING)
- **分区类型**: 按日期分区
- **分区格式**: `YYYY-MM-DD` (例如: `pt='2025-01-20'`)
- **使用示例**: `WHERE pt = '${-1d_pt}'`

---

## 字段使用说明

### beiyong2 字段解析

`beiyong2` 字段包含距离信息，格式为：`直线距离:X.XXkm`

SQL解析示例：
```sql
CASE 
    WHEN INSTR(beiyong2, '直线距离:') > 0 AND INSTR(beiyong2, 'km') > 0 
    THEN CAST(SUBSTR(beiyong2, INSTR(beiyong2, '直线距离:') + 5, 
                     INSTR(beiyong2, 'km') - (INSTR(beiyong2, '直线距离:') + 5)) AS DOUBLE)
    ELSE NULL  
END AS distance_km
```

---

## 常用查询条件

根据SQL使用情况，常见查询条件：
- `pt = '${-1d_pt}'` (按分区查询)
- 通过 `beiyong2` 字段提取距离信息，筛选 `distance_km > 1` 的记录

---

## 建表语句

```sql
-- 请在线上数据库执行以下命令获取完整建表语句：
-- SHOW CREATE TABLE rpt.rpt_complain_order_details;
```

---

## 备注

- 此表用于存储投诉订单的详细信息
- `beiyong2` 字段包含签到距离信息，用于判断异常距离签到




