# 表结构：rpt.rpt_weixiu_abnormal_p

## 表基本信息

- **数据库名**: `rpt`
- **表名**: `rpt_weixiu_abnormal_p`
- **表说明**: 维修异常签到平铺表（明细表）
- **更新日期**: [待更新]

---

## 字段信息

> ⚠️ **注意**: 以下字段信息基于SQL使用情况提取，完整字段列表请通过 `DESC` 或 `SHOW CREATE TABLE` 命令获取

| 序号 | 字段名 | 数据类型 | 是否允许NULL | 默认值 | 字段说明 |
|------|--------|----------|--------------|--------|----------|
| 1 | city | STRING | YES | NULL | 城市（经过映射处理） |
| 2 | 供应商 | STRING | YES | NULL | 供应商名称（经过映射处理） |
| 3 | 服务者UCID | BIGINT | YES | NULL | 服务者UCID |
| 4 | 服务者姓名 | STRING | YES | NULL | 服务者姓名 |
| 5 | 异常签到原因 | STRING | YES | NULL | 异常签到原因（'短时间多次' 或 '异常距离'） |
| 6 | 异常签到开始时间 | TIMESTAMP | YES | NULL | 异常签到开始时间 |
| 7 | 房源id | BIGINT | YES | NULL | 房源ID |
| 8 | 服务单id | STRING | YES | NULL | 服务单ID |
| 9 | 订单状态 | STRING | YES | NULL | 订单状态（经过映射） |
| 10 | 紧急单标识 | STRING | YES | NULL | 紧急单标识（经过映射） |
| 11 | 营销大区/大部 | STRING | YES | NULL | 营销大区/大部 |
| 12 | pt | STRING | NO | NULL | 分区字段（日期分区） |

---

## 分区信息

- **分区字段**: `pt` (STRING)
- **分区类型**: 按日期分区
- **分区格式**: `YYYY-MM-DD` (例如: `pt='2025-01-20'`)
- **使用示例**: `INSERT OVERWRITE TABLE ... PARTITION (pt='${-1d_pt}')`

---

## 字段映射逻辑

### city 字段映射

```sql
CASE
    WHEN city_name = '北京市' AND manager_marketing_name IN ('京东事业部','京东南事业部','京南事业部','京西南事业部') 
    THEN '惠居京南'
    WHEN city_name = '北京市' AND manager_marketing_name IN ('京西北事业部','京中事业部','京北事业部','京西事业部','京东北事业部') 
    THEN '惠居京北' 
    ELSE city_name 
END AS city
```

### 供应商字段映射

```sql
CASE 
    WHEN city_name IN ('广州市','深圳市','济南市') AND service_order_supplier_name = '上海翊帮人科技有限公司' 
    THEN '上海彼方建筑装饰工程有限公司'
    WHEN city_name = '深圳市' AND service_order_supplier_name = '云万服（广州）生活服务有限公司' 
    THEN '寰诚建筑（深圳）有限公司'
    ELSE service_order_supplier_name
END AS 供应商
```

### 订单状态映射

```sql
CASE 
    WHEN order_status='8' THEN '待报价' 
    WHEN order_status='10' THEN '待平台派单' 
    WHEN order_status='20' THEN '待供应商接单' 
    WHEN order_status='21' THEN '待供应商派单' 
    WHEN order_status='22' THEN '待服务者接单' 
    WHEN order_status='23' THEN '待服务' 
    WHEN order_status='24' THEN '服务中' 
    WHEN order_status='30' THEN '待付款'  
    WHEN order_status='40' THEN '订单完成'  
    WHEN order_status='50' THEN '订单取消'  
    WHEN order_status='11' THEN '成团中'  
    ELSE order_status 
END AS 订单状态
```

### 紧急单标识映射

```sql
CASE 
    WHEN performance_mode='0' THEN '普通单' 
    WHEN performance_mode='1' THEN '紧急单'  
    WHEN performance_mode='2' THEN '加急单'  
    ELSE performance_mode 
END AS 紧急单标识
```

---

## 数据写入方式

使用 `INSERT OVERWRITE` 方式写入，覆盖指定分区的数据：

```sql
INSERT OVERWRITE TABLE rpt.rpt_weixiu_abnormal_p PARTITION (pt='${-1d_pt}')
SELECT ...
```

---

## 与汇总表的区别

- **rpt_weixiu_abnormal_checkin_list**: 汇总表，短时间多次签到会聚合为一条记录，包含房源列表、服务单列表等
- **rpt_weixiu_abnormal_p**: 平铺表，每条异常签到记录单独一行，包含更多明细字段（订单状态、紧急单标识等）

---

## 建表语句

```sql
-- 请在线上数据库执行以下命令获取完整建表语句：
-- SHOW CREATE TABLE rpt.rpt_weixiu_abnormal_p;
```

---

## 备注

- 此表是异常签到数据的平铺明细表
- 每条记录对应一个异常签到的服务单
- 包含订单状态、紧急单标识等额外信息




