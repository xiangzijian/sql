-- 维修咨询率统计明细：宁波市2025年5月
-- 用于核对统计数据的准确性

WITH
-- 1. 租期维修订单基础数据
base_repair_orders AS (
 SELECT
 o.service_order_code,
 o.order_no,
 o.city_name,
 SUBSTR(o.order_create_time, 1, 7) AS order_month,
 o.order_create_time,
 o.order_creator_type,
 o.first_suspend_time,
 o.service_order_complete_time,
 o.order_status,
 CASE 
 WHEN o.order_creator_type = 1 THEN '客户下单' 
 ELSE '非客户下单' 
 END AS creator_type_name,
 CASE 
 WHEN o.order_creator_type = 1 THEN 1 
 ELSE 0 
 END AS is_customer_created,
 -- 是否挂起
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
 AND o.city_name = '宁波市'
 AND SUBSTR(o.order_create_time, 1, 7) = '2025-05'
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

-- 2. 改约订单识别
change_appointment_orders AS (
 SELECT DISTINCT
 service_order_code,
 MIN(operate_time) AS first_change_time
 FROM
 dw.dw_fas_jiafu_dispatch_service_order_operate_history_da
 WHERE
 pt = '20251231000000'
 AND operate_type_name = '修改服务时间'
 AND service_order_code IS NOT NULL
 GROUP BY service_order_code
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

-- 4. 咨询工单明细
consultation_details AS (
 SELECT
 r.repair_order AS order_no,
 t.ticket_id,
 t.three_current_name,
 t.ctime AS ticket_created_time,
 t.close_time AS ticket_close_time,
 t.ticket_status,
 CASE 
 WHEN t.ticket_status = 1 THEN '待处理'
 WHEN t.ticket_status = 2 THEN '待跟进'
 WHEN t.ticket_status = 3 THEN '已解决'
 WHEN t.ticket_status = 4 THEN '无法解决'
 WHEN t.ticket_status = 5 THEN '无效建单'
 WHEN t.ticket_status = 6 THEN '重复单'
 ELSE '未知'
 END AS ticket_status_name
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
 )

-- 最终明细输出
SELECT
 r.city_name AS `城市`,
 r.order_month AS `月份`,
 r.service_order_code AS `服务单编码`,
 r.order_no AS `维修单号`,
 r.order_create_time AS `下单时间`,
 r.order_status AS `订单状态`,
 r.service_order_complete_time AS `完工时间`,
 
 -- 订单属性
 r.creator_type_name AS `创建人类型`,
 CASE WHEN r.is_customer_created = 1 THEN '是' ELSE '否' END AS `是否客户下单`,
 
 -- 改约信息
 CASE WHEN ca.service_order_code IS NOT NULL THEN '是' ELSE '否' END AS `是否改约`,
 ca.first_change_time AS `首次改约时间`,
 
 -- 挂起信息
 CASE WHEN r.is_suspended = 1 THEN '是' ELSE '否' END AS `是否挂起`,
 r.first_suspend_time AS `首次挂起时间`,
 
 -- 包外信息
 CASE WHEN ofr.service_order_code IS NOT NULL THEN '是' ELSE '否' END AS `是否包外`,
 
 -- 正常流程标识
 CASE 
 WHEN ca.service_order_code IS NULL 
 AND r.is_suspended = 0 
 AND ofr.service_order_code IS NULL 
 THEN '是' 
 ELSE '否' 
 END AS `是否正常流程`,
 
 -- 咨询信息
 COUNT(DISTINCT c.ticket_id) AS `咨询工单数`,
 CASE WHEN COUNT(DISTINCT c.ticket_id) > 0 THEN '有咨询' ELSE '无咨询' END AS `是否有咨询`,
 
 -- 咨询明细（拼接）
 CONCAT_WS('|', COLLECT_SET(c.ticket_id)) AS `咨询工单ID列表`,
 CONCAT_WS('|', COLLECT_SET(c.three_current_name)) AS `咨询类型列表`,
 CONCAT_WS('|', COLLECT_SET(c.ticket_created_time)) AS `咨询创建时间列表`,
 CONCAT_WS('|', COLLECT_SET(c.ticket_status_name)) AS `咨询状态列表`

FROM
 base_repair_orders r
LEFT JOIN
 change_appointment_orders ca
 ON r.service_order_code = ca.service_order_code
LEFT JOIN
 out_free_repair_orders ofr
 ON r.service_order_code = ofr.service_order_code
LEFT JOIN
 consultation_details c
 ON r.order_no = c.order_no
 AND SUBSTR(c.ticket_created_time, 1, 7) = r.order_month
GROUP BY
 r.city_name,
 r.order_month,
 r.service_order_code,
 r.order_no,
 r.order_create_time,
 r.order_status,
 r.service_order_complete_time,
 r.creator_type_name,
 r.is_customer_created,
 r.is_suspended,
 r.first_suspend_time,
 ca.service_order_code,
 ca.first_change_time,
 ofr.service_order_code
ORDER BY
 r.order_create_time,
 r.order_no
