# 表结构：rpt.rpt_fas_light_hosting_order_detail_da

## 表基本信息

- **数据库名**: `rpt`
- **表名**: `rpt_fas_light_hosting_order_detail_da`
- **表说明**: FAS轻托管订单明细日表
- **更新日期**: [待更新]

---

## 字段信息

> ⚠️ **注意**: 以下字段信息基于SQL使用情况提取，完整字段列表请通过 `DESC` 或 `SHOW CREATE TABLE` 命令获取

| 序号 | 字段名 | 数据类型 | 是否允许NULL | 默认值 | 字段说明 |
|------|--------|----------|--------------|--------|----------|
| 1 | order_no | STRING | YES | NULL | 订单号 |
| 2 | create_time | TIMESTAMP | YES | NULL | 创建时间 |
| 3 | order_after_sign_diff_out | STRING/DOUBLE | YES | NULL | 签到后差异输出 |
| 4 | service_time_end | TIMESTAMP | YES | NULL | 服务结束时间 |
| 5 | original_service_time_end | TIMESTAMP | YES | NULL | 原始服务结束时间 |
| 6 | vison_type | STRING | YES | NULL | 版本类型（'4.0'表示4.0版本） |
| 7 | service_name | STRING | YES | NULL | 服务名称（'维修','燃气'） |
| 8 | order_type | STRING | YES | NULL | 订单类型（'16'表示维修订单） |
| 9 | label_group | STRING | YES | NULL | 标签组 |
| 10 | commodity_name_list1 | STRING | YES | NULL | 商品名称列表1 |
| 11 | supplier_name | STRING | YES | NULL | 供应商名称 |
| 12 | pt | STRING | NO | NULL | 分区字段（日期分区） |

---

## 分区信息

- **分区字段**: `pt` (STRING)
- **分区类型**: 按日期分区
- **分区格式**: `YYYY-MM-DD` (例如: `pt='2025-01-20'`)
- **使用示例**: `WHERE pt = '${-1d_pt}'`

---

## 常用查询条件

根据SQL使用情况，常见查询条件：
- `vison_type = '4.0'` (4.0版本)
- `service_name IN ('维修','燃气')` (维修和燃气服务)
- `order_type = '16'` (维修订单)
- `label_group NOT IN ('8')` (排除特定标签组)
- `commodity_name_list1 != '漏水专项检修'` (排除漏水专项检修)
- `commodity_name_list1 NOT IN ('夏季空调预检','SCM00300001672373','漏水专项检修','消防器材','定损','漏水定损','火灾定损','其他定损','京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')` (排除特定商品)
- `supplier_name NOT IN ('上海兰宫建筑装饰有限公司','上海尚礼实业有限公司','上海苏皖贸易有限公司','上海再旭保洁服务有限公司','源和里仁家具海安有限公司')` (排除特定供应商)
- `create_time >= '2025-05-01'` (创建时间筛选)

---

## 字段计算逻辑

### final_time 计算

```sql
CASE 
    WHEN service_time_end > original_service_time_end 
    THEN service_time_end 
    ELSE original_service_time_end 
END AS final_time
```

取 `service_time_end` 和 `original_service_time_end` 中的较大值作为最终时间。

---

## 建表语句

```sql
-- 请在线上数据库执行以下命令获取完整建表语句：
-- SHOW CREATE TABLE rpt.rpt_fas_light_hosting_order_detail_da;
```

---

## 备注

- 此表用于存储FAS轻托管订单的详细信息
- 主要用于筛选符合条件的维修和燃气订单
- 通过多个条件组合筛选，排除特定商品和供应商




