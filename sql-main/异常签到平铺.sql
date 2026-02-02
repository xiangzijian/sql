WITH
sign_details AS (
  SELECT
    service_order_professional_ucid AS `服务者UCID`,
    first_sign_time AS `签到时间`,
    unix_timestamp(first_sign_time) AS ts,   -- 秒级时间戳
    house_resource_id AS `房源ID`,
    service_order_code AS `服务单id`
  FROM (
    SELECT DISTINCT
      service_order_professional_ucid,
      first_sign_time,
      house_resource_id,
      service_order_code
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${-1d_pt}'
      AND order_type = 16
      AND label_group NOT IN ('8','1','25')
      AND lease_status IN (2,3)
      AND house_resource_id IS NOT NULL
      AND first_sign_time >= '2025-05-01'
	  and service_order_professional_ucid !=-911
  ) s
),
win_pairs AS (
  SELECT
    a.`服务者UCID`,
    a.`服务单id` AS `锚点服务单id`,
    a.`签到时间` AS `窗口锚点时间`,
    a.ts AS anchor_ts,
    b.`服务单id` AS `窗口内服务单id`,
    b.`签到时间` AS `窗口内签到时间`,
    b.`房源ID` AS `窗口内房源ID`
  FROM sign_details a
  JOIN sign_details b
    ON a.`服务者UCID` = b.`服务者UCID`
  WHERE b.ts >= a.ts
    AND b.ts <= a.ts + 600
),
window_stats_pre AS (
  SELECT
    `服务者UCID`,
    `锚点服务单id`,
    COUNT(DISTINCT `窗口内服务单id`) AS cnt_win_orders,
    COUNT(DISTINCT `窗口内房源ID`)  AS cnt_win_houses
  FROM win_pairs
  GROUP BY `服务者UCID`, `锚点服务单id`
),
window_stats AS (
  SELECT
    `服务者UCID`,
    `锚点服务单id`
  FROM window_stats_pre
  WHERE cnt_win_orders >= 3
    AND cnt_win_houses >= 3
),
excluded_orders_with_count AS (
  SELECT DISTINCT
    p.`窗口内服务单id` AS `服务单id`
  FROM win_pairs p
  JOIN window_stats v
    ON p.`服务者UCID` = v.`服务者UCID`
   AND p.`锚点服务单id` = v.`锚点服务单id`
)

insert overwrite table rpt.rpt_weixiu_abnormal_p partition (pt='${-1d_pt}')

SELECT 
  case
    when t1.city_name = '北京市' and t1.manager_marketing_name in ('京东事业部','京东南事业部','京南事业部','京西南事业部') then '惠居京南'
    when t1.city_name = '北京市' and t1.manager_marketing_name in ('京西北事业部','京中事业部','京北事业部','京西事业部','京东北事业部') then '惠居京北' 
    ELSE t1.city_name 
  END AS city,
  CASE 
    WHEN t1.city_name IN ('广州市','深圳市','济南市') AND t1.service_order_supplier_name = '上海翊帮人科技有限公司' THEN '上海彼方建筑装饰工程有限公司'
    WHEN t1.city_name = '深圳市' AND t1.service_order_supplier_name = '云万服（广州）生活服务有限公司' THEN '寰诚建筑（深圳）有限公司'
    ELSE t1.service_order_supplier_name
  END AS `供应商`,
  t1.service_order_professional_ucid AS `服务者UCID`,
  t1.service_order_professional_name AS `服务者姓名`,
  CASE 
    WHEN t2.`服务单id` IS NOT NULL THEN '短时间多次' 
    WHEN t4.feedback_type = 1 OR t5.sign_exception = 1 THEN '异常距离' 
    ELSE '异常距离' 
  END AS `异常签到原因`,
  t1.first_sign_time AS `异常签到开始时间`,
  t1.house_resource_id as `房源id`,
  t1.service_order_code as `服务单id`,
  case when t1.order_status='8' then '待报价' when t1.order_status='10' then '待平台派单' when t1.order_status='20' then '待供应商接单' when t1.order_status='21' then '待供应商派单' when t1.order_status='22' then '待服务者接单' 
  when t1.order_status='23' then '待服务' 
  when t1.order_status='24' then '服务中' when t1.order_status='30' then '待付款'  when t1.order_status='40' then '订单完成'  when t1.order_status='50' then '订单取消'  when t1.order_status='11' then '成团中'  else t1.order_status end as `订单状态`,
  case when t1.performance_mode='0' then '普通单' when t1.performance_mode='1' then '紧急单'  when t1.performance_mode='2' then '加急单'  else  t1.performance_mode end  as `紧急单标识`,
t1.manager_marketing_name as `营销大区/大部`
FROM olap.olap_hj_fas_main_order_service_info_da t1
INNER JOIN (
  SELECT
    order_no AS oth_orderno,
    create_time,
    order_after_sign_diff_out,
    CASE WHEN service_time_end > original_service_time_end THEN service_time_end ELSE original_service_time_end END AS final_time
  FROM rpt.rpt_fas_light_hosting_order_detail_da
  WHERE pt = '${-1d_pt}'
    AND vison_type = '4.0'
    AND service_name IN ('维修','燃气')
    AND order_type = '16'
    AND label_group NOT IN ('8')
    AND commodity_name_list1 != '漏水专项检修'
    AND commodity_name_list1 NOT IN ('夏季空调预检','SCM00300001672373','漏水专项检修','消防器材','定损','漏水定损','火灾定损','其他定损','京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')
    AND supplier_name NOT IN ('上海兰宫建筑装饰有限公司','上海尚礼实业有限公司','上海苏皖贸易有限公司','上海再旭保洁服务有限公司','源和里仁家具海安有限公司')
    AND create_time >= '2025-05-01'
) b
  ON t1.order_no = b.oth_orderno
LEFT JOIN excluded_orders_with_count t2
  ON t1.service_order_code = t2.`服务单id`
LEFT JOIN ( select service_order_code,max(feedback_type) as feedback_type from ods.ods_plat_jiafu_dispatch_service_order_sign_in_feedback_di where pt = '${-1d_pt}' group by service_order_code )   t4
  ON t1.service_order_code = t4.service_order_code
LEFT JOIN ( select service_order_code,max(sign_exception) as sign_exception from ods.ods_plat_jiafu_dispatch_service_order_ext_info_da where pt = '${-1d_pt}' group by service_order_code ) t5
  ON t1.service_order_code = t5.service_order_code
WHERE
  t1.pt = '${-1d_pt}'
  AND t1.order_type = 16 
  AND t1.label_group NOT IN ('8','1','25') 
  AND t1.lease_status IN (2,3) 
  AND t1.house_resource_id IS NOT NULL 
  AND t1.service_order_code IS NOT NULL 
  AND ((t1.sign_state = 1 and (t4.feedback_type = 1 OR t5.sign_exception = 1)) OR t2.`服务单id` IS not NULL)
  AND t1.first_sign_time >= '2025-05-01'
