# 表结构：olap.olap_hj_fas_main_order_service_info_da

## 表基本信息

- **数据库名**: `olap`
- **表名**: `olap_hj_fas_main_order_service_info_da`
- **表说明**: 主订单服务信息日表
- **更新日期**: [待更新]

---

## 字段信息

> ⚠️ **注意**: 以下字段信息基于SQL使用情况提取，完整字段列表请通过 `DESC` 或 `SHOW CREATE TABLE` 命令获取

| 序号 | 字段名 | 数据类型 | 是否允许NULL | 默认值 | 字段说明 |
|------|--------|----------|--------------|--------|----------|
| 1 | service_order_professional_ucid | BIGINT | YES | NULL | 服务者UCID |
| 2 | first_sign_time | TIMESTAMP | YES | NULL | 首次签到时间 |
| 3 | house_resource_id | BIGINT | YES | NULL | 房源ID |
| 4 | service_order_code | STRING | YES | NULL | 服务单编码 |
| 5 | order_no | STRING | YES | NULL | 订单号 |
| 6 | sign_state | INT | YES | NULL | 签到状态（1表示已签到） |
| 7 | pt | STRING | NO | NULL | 分区字段（日期分区） |
| 8 | order_type | INT | YES | NULL | 订单类型（16表示维修订单） |
| 9 | label_group | STRING | YES | NULL | 标签组 |
| 10 | lease_status | INT | YES | NULL | 租赁状态（2,3表示有效状态） |
| 11 | city_name | STRING | YES | NULL | 城市名称 |
| 12 | manager_marketing_name | STRING | YES | NULL | 营销经理名称/营销大区 |
| 13 | manager_corp_name | STRING | YES | NULL | 公司名称 |
| 14 | service_order_supplier_name | STRING | YES | NULL | 供应商名称 |
| 15 | service_order_professional_name | STRING | YES | NULL | 服务者姓名 |
| 16 | order_creator_marketing_name | STRING | YES | NULL | 订单创建者营销名称/营销大区/大部 |
| 17 | order_status | STRING | YES | NULL | 订单状态 |
| 18 | performance_mode | STRING | YES | NULL | 履约模式（0:普通单, 1:紧急单, 2:加急单） |

---

## 分区信息

- **分区字段**: `pt` (STRING)
- **分区类型**: 按日期分区
- **分区格式**: `YYYY-MM-DD` (例如: `pt='2025-01-20'`)
- **使用示例**: `WHERE pt = '${-1d_pt}'`

---

## 常用查询条件

根据SQL使用情况，常见查询条件：
- `order_type = 16` (维修订单)
- `label_group NOT IN ('8','1','25')` (排除特定标签组)
- `lease_status IN (2,3)` (有效租赁状态)
- `house_resource_id IS NOT NULL` (房源ID不为空)
- `first_sign_time >= '2025-05-01'` (签到时间筛选)
- `service_order_professional_ucid != -911` (排除特定服务者)

---

## 建表语句

```sql
-- 请在线上数据库执行以下命令获取完整建表语句：
-- SHOW CREATE TABLE olap.olap_hj_fas_main_order_service_info_da;
```

---

## 备注

- 此表用于存储主订单服务信息
- 包含服务者、房源、订单等关键信息
- 按日期分区，便于按时间范围查询




