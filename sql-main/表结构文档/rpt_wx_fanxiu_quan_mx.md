# rpt_wx_fanxiu_quan_mx - 维修返修全量明细表

## 表基本信息
- **表名**: rpt.rpt_wx_fanxiu_quan_mx
- **表类型**: 分区表
- **分区字段**: pt (日期分区)
- **更新频率**: 日更新
- **数据范围**: 2025年5月及以后的完工订单

## 表结构

| 英文字段名 | 中文字段名 | 字段类型 | 字段说明 | 备注 |
|-----------|-----------|---------|---------|------|
| service_order_code | 服务单编码 | STRING | 服务单编码 | |
| city_name | 城市 | STRING | 城市名称 | |
| manager_marketing_name | 营销大区/大部 | STRING | 营销大区/大部名称 | |
| manager_area_name | 业务区域/组 | STRING | 业务区域/组名称 | |
| bizcircle_name | 商圈 | STRING | 商圈名称 | |
| resblock_name | 楼盘 | STRING | 楼盘名称 | |
| service_order_supplier_name | 供应商 | STRING | 供应商名称 | |
| service_order_professional_ucid | 服务者ucid | STRING | 服务者UCID | |
| service_order_professional_name | 服务者姓名 | STRING | 服务者姓名 | |
| house_resource_id | 房源编码 | STRING | 房源编码 | |
| service_order_complete_time | 完工时间 | STRING | 完工时间 | |
| repair_type | 维修类型 | STRING | 维修类型 | 检修/租后维修 |
| order_no_1 | 完工订单号 | STRING | 完工订单号 | |
| product_name_1 | 完工商品名称 | STRING | 完工商品名称 | |
| fanxiu_order_code | 返修单号 | STRING | 返修单号 | 可能为空 |
| relate_order_code | 关联单号 | STRING | 返修关联的原订单号 | 可能为空 |
| fanxiu_time | 返修时间 | STRING | 返修时间 | 可能为空 |
| fanxiu_product_code | 返修商品 | STRING | 返修商品编码 | 可能为空 |
| fanxiu_product_name | 返修商品名称 | STRING | 返修商品名称 | 可能为空 |
| fanxiu_service_order_professional_name | 返修服务者姓名 | STRING | 返修服务者姓名 | 可能为空 |
| fanxiu_service_order_professional_ucid | 返修服务者ucid | STRING | 返修服务者UCID | 可能为空 |
| fanxiu_supplier_name | 返修商 | STRING | 返修供应商名称 | 可能为空 |
| service_order_supplier_code | 供应商编码 | STRING | 供应商编码 | |
| is_6_item | 是否6项商品 | INT | 是否为6项重点商品 | 1-是, 0-否；6项商品：马桶、空调、洗手池、洗衣机、燃气灶、淋浴器 |
| fanxiu_1 | 是否返修 | INT | 是否发生返修 | 1-发生返修, 0-未返修 |
| pt | 分区字段 | STRING | 分区字段 | 格式：yyyyMMdd |

## 数据说明

### 维修类型判断逻辑
- **检修**: examine_task_type = 3 或者 (examine_task_type 不为 3,12 且 lease_status 为 -1,1)
- **租后维修**: 其他情况

### 是否6项商品判断逻辑
6项商品包括：马桶、空调、洗手池、洗衣机、燃气灶、淋浴器

### 返修判断逻辑
- 通过关联表 `rpt_plat_beijia_transaction_trade_order_relate_info_di` 获取返修记录
- 只保留最近一次返修记录（按返修时间正序，取第一条）
- 通过完工订单号和商品编码关联返修单

## 数据过滤条件

### 基础订单过滤
- order_type = 16（维修订单）
- label_group NOT IN ('8')（排除特定标签组）
- 完工时间 >= 2025-06-01
- 完工时间年月 >= 2025-05

### 排除的商品
- 漏水专项检修（commodity_code: SCM00300001672373）
- 夏季空调预检
- 消防器材

### 排除的供应商
- 上海兰宫建筑装饰有限公司
- 上海尚礼实业有限公司
- 上海苏皖贸易有限公司
- 上海再旭保洁服务有限公司
- 源和里仁家具海安有限公司

### 返修记录过滤
- relate_type = '1'（关联类型为返修）
- del_status = '1'（未删除）
- 时间范围：20250501000000 至最新分区

## 上游依赖表

| 表名 | 说明 |
|------|------|
| olap.olap_hj_fas_main_order_service_info_da | 维修订单服务信息主表 |
| rpt.rpt_fas_light_hosting_order_detail_da | 轻托管订单明细表 |
| dw.dw_fas_jiafu_dispatch_service_order_product_da | 服务单商品信息表 |
| rpt.rpt_plat_beijia_transaction_trade_order_relate_info_di | 订单关联关系表（返修关系） |
| olap.olap_hj_fas_main_order_commodity_da | 订单商品表 |

## 使用场景
- 维修返修率分析
- 供应商/服务者返修情况统计
- 6项商品返修监控
- 检修与租后维修返修对比分析
- 区域/城市返修趋势分析

## 注意事项
1. 该表使用 DISTINCT 去重，确保每个完工订单+商品的唯一性
2. 返修记录关联时，只保留最近一次返修
3. 返修相关字段可能为空，表示该订单未发生返修
4. 维修类型判断依赖于 examine_task_type 和 lease_status 字段
5. 数据从2025年5月开始统计
