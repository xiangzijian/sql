-- 维修咨询率统计：按月按城市
-- 统计租期维修单量、咨询量及各类细分指标
-- 时间范围：2025年1-12月
-- 租期订单筛选参考健康度.sql，去掉漏水和定损

WITH
-- 1. 租期维修订单基础数据（参考健康度筛选逻辑）
base_repair_orders AS (
 SELECT
 o.service_order_code,
 o.city_name,
 SUBSTR(o.order_create_time, 1, 7) AS order_month,
 o.order_creator_type,
 o.order_no,
 o.first_suspend_time,
 CASE 
 WHEN o.order_creator_type = 1 THEN 1 
 ELSE 0 
 END AS is_customer_created,
 -- 是否挂起（通过挂起时间判断）
 CASE 
 WHEN o.first_suspend_time IS NOT NULL 
 AND o.first_suspend_time != '1000-01-01 00:00:00' 
 AND SUBSTR(o.first_suspend_time, 1, 4) NOT IN ('1000', '1990', '2050')
 THEN 1 
 ELSE 0 
 END AS is_suspended
 FROM
 olap.olap_hj_fas_main_order_service_info_da o
 INNER JOIN
 rpt.rpt_fas_light_hosting_order_detail_da b
 ON o.order_no = b.order_no
 WHERE
 o.pt = '20251231000000'
 AND b.pt = '20251231000000'
 AND o.order_create_time BETWEEN '2025-01-01 00:00:00' AND '2025-12-31 23:59:59'
 AND o.order_type = '16'
 AND o.label_group NOT IN ('8')
 AND o.lease_status IN (2, 3)
 -- 参考健康度的筛选条件
 AND b.vison_type = '4.0'
 AND b.service_name IN ('维修', '燃气')
 AND b.order_type = '16'
 AND b.label_group NOT IN ('8')
 -- 去掉漏水和定损
 AND b.commodity_name_list1 NOT IN (
 '夏季空调预检',
 'SCM00300001672373',
 '漏水专项检修',
 '消防器材',
 '定损',
 '漏水定损',
 '火灾定损',
 '其他定损',
 '京北漏水定损',
 '京南漏水定损',
 '京北火灾定损',
 '京南火灾定损',
 '京北其他定损',
 '京南其他定损'
 )
 -- 排除特定供应商
 AND b.supplier_name NOT IN (
 '上海兰宫建筑装饰有限公司',
 '上海尚礼实业有限公司',
 '上海苏皖贸易有限公司',
 '上海再旭保洁服务有限公司',
 '源和里仁家具海安有限公司',
 '匠云（北京）科技有限公司'
 )
 ),

-- 2. 改约订单识别（修改过服务时间的订单）
change_appointment_orders AS (
 SELECT DISTINCT
 service_order_code
 FROM
 dw.dw_fas_jiafu_dispatch_service_order_operate_history_da
 WHERE
 pt = '20251231000000'
 AND operate_type_name = '修改服务时间'
 AND service_order_code IS NOT NULL
 ),

-- 3. 包外订单识别
out_free_repair_orders AS (
 SELECT DISTINCT
 service_order_code
 FROM
 olap.olap_hj_fas_main_order_service_out_free_repair_plan_da
 WHERE
 pt = '20251231000000'
 AND service_order_code IS NOT NULL
 ),

-- 4. 咨询工单数据（通过关联表连接维修单和咨询工单）
consultation_tickets AS (
 SELECT
 r.repair_order AS order_no,
 t.ticket_id,
 t.three_current_name,
 t.city_name,
 SUBSTR(t.ctime, 1, 7) AS ticket_month
 FROM
 ods.ods_plat_private_domain_ticket_repair_order_relation_da r
 INNER JOIN
 rpt.rpt_trusteeship_private_fuwu_houseout_renter_da t
 ON r.ticket_id = t.ticket_id
 WHERE
 r.pt = '20251231000000'
 AND t.pt = '20251231000000'
 AND t.parent_name = '维修'
 AND t.ticket_status NOT IN (5, 6)
 AND t.three_current_name IN (
 '加急维修订单',
 '维修上门时间确认',
 '维修无人二次跟进',
 '维修师傅电话确认',
 '下单后无人联系'
 )
 AND r.repair_order IS NOT NULL
 ),

-- 5. 订单和各维度关联
order_with_flags AS (
 SELECT
 r.service_order_code,
 r.order_no,
 r.city_name,
 r.order_month,
 r.order_creator_type,
 r.is_customer_created,
 r.is_suspended,
 CASE WHEN ca.service_order_code IS NOT NULL THEN 1 ELSE 0 END AS has_change_appointment,
 CASE WHEN ofr.service_order_code IS NOT NULL THEN 1 ELSE 0 END AS is_out_free_repair
 FROM
 base_repair_orders r
 LEFT JOIN
 change_appointment_orders ca
 ON r.service_order_code = ca.service_order_code
 LEFT JOIN
 out_free_repair_orders ofr
 ON r.service_order_code = ofr.service_order_code
 ),

-- 6. 订单和咨询关联
order_with_consultation AS (
 SELECT
 r.service_order_code,
 r.order_no,
 r.city_name,
 r.order_month,
 r.order_creator_type,
 r.is_customer_created,
 r.has_change_appointment,
 r.is_suspended,
 r.is_out_free_repair,
 COUNT(DISTINCT c.ticket_id) AS consultation_count
 FROM
 order_with_flags r
 LEFT JOIN
 consultation_tickets c
 ON r.order_no = c.order_no
 AND r.order_month = c.ticket_month
 AND r.city_name = c.city_name
 GROUP BY
 r.service_order_code,
 r.order_no,
 r.city_name,
 r.order_month,
 r.order_creator_type,
 r.is_customer_created,
 r.has_change_appointment,
 r.is_suspended,
 r.is_out_free_repair
 )

-- 最终统计输出
SELECT
 city_name AS `城市`,
 order_month AS `月份`,
 
 -- 订单量统计
 COUNT(DISTINCT service_order_code) AS `租期维修单量`,
 COUNT(DISTINCT CASE WHEN is_customer_created = 1 THEN service_order_code END) AS `客户下单量`,
 COUNT(DISTINCT CASE WHEN is_customer_created = 0 THEN service_order_code END) AS `非客户下单量`,
 
 -- 正常流程订单量（无挂起无改约无包外）
 COUNT(DISTINCT CASE 
 WHEN has_change_appointment = 0 
 AND is_suspended = 0 
 AND is_out_free_repair = 0 
 THEN service_order_code 
 END) AS `正常流程订单量`,
 
 -- 包外订单量
 COUNT(DISTINCT CASE WHEN is_out_free_repair = 1 THEN service_order_code END) AS `发起包外订单量`,
 
 -- 有咨询的订单量
 COUNT(DISTINCT CASE WHEN consultation_count > 0 THEN service_order_code END) AS `有咨询的订单量`,
 
 -- 客户下单有咨询订单量
 COUNT(DISTINCT CASE WHEN is_customer_created = 1 AND consultation_count > 0 THEN service_order_code END) AS `客户下单有咨询订单量`,
 
 -- 非客户下单有咨询订单量
 COUNT(DISTINCT CASE WHEN is_customer_created = 0 AND consultation_count > 0 THEN service_order_code END) AS `非客户下单有咨询订单量`,
 
 -- 正常流程有咨询的订单量
 COUNT(DISTINCT CASE 
 WHEN has_change_appointment = 0 
 AND is_suspended = 0 
 AND is_out_free_repair = 0 
 AND consultation_count > 0 
 THEN service_order_code 
 END) AS `正常流程有咨询订单量`,
 
 -- 包外流程有咨询的订单量
 COUNT(DISTINCT CASE WHEN is_out_free_repair = 1 AND consultation_count > 0 THEN service_order_code END) AS `包外流程有咨询订单量`
 
FROM
 order_with_consultation
GROUP BY
 city_name,
 order_month
ORDER BY
 city_name,
 order_month
