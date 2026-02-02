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
-- 窗口内配对
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
-- 单窗口统计
window_stats AS (
  SELECT
    `服务者UCID`,
    `锚点服务单id`,
    `窗口锚点时间` AS `10分钟窗口起始时间`,
    anchor_ts,
    MIN(`窗口内签到时间`) AS `第一次签到时间`,
    COUNT(DISTINCT `窗口内服务单id`) AS `10分钟窗口签到次数`,
    COUNT(DISTINCT `窗口内房源ID`)  AS `不同房源数`,
    collect_set(CAST(`窗口内房源ID` AS string)) AS `10分钟内签到房源列表`,
    collect_set(CAST(`窗口内服务单id` AS string)) AS `10分钟内签到服务单列表`,
    collect_set(date_format(`窗口内签到时间`, 'yyyy-MM-dd HH:mm:ss')) AS `10分钟内签到时间列表`
  FROM win_pairs
  GROUP BY `服务者UCID`, `锚点服务单id`, `窗口锚点时间`, anchor_ts
  HAVING COUNT(DISTINCT `窗口内服务单id`) >= 3
     AND COUNT(DISTINCT `窗口内房源ID`)  >= 3
),
anchors_only AS (
  SELECT
    `服务者UCID`,
    `锚点服务单id`,
    `10分钟窗口起始时间`,
    anchor_ts
  FROM window_stats
),
ordered_anchors AS (
  SELECT
    a.*,
    LAG(anchor_ts) OVER (PARTITION BY `服务者UCID` ORDER BY anchor_ts) AS prev_anchor_ts
  FROM anchors_only a
),
anchor_grp_step AS (
  SELECT
    *,
    CASE WHEN prev_anchor_ts IS NULL OR anchor_ts - prev_anchor_ts > 600 THEN 1 ELSE 0 END AS new_grp_flag
  FROM ordered_anchors
),
anchor_grp_id AS (
  SELECT
    *,
    SUM(new_grp_flag) OVER (PARTITION BY `服务者UCID` ORDER BY anchor_ts ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS anchor_grp_id
  FROM anchor_grp_step
),
anchor_grp_first AS (
  SELECT
    `服务者UCID`,
    anchor_grp_id,
    `锚点服务单id`,
    `10分钟窗口起始时间`
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY `服务者UCID`, anchor_grp_id ORDER BY anchor_ts) AS rn
    FROM anchor_grp_id
  ) t
  WHERE rn = 1
),
group_stats AS (
  SELECT
    ag.`服务者UCID`,
    ag.anchor_grp_id,
    f.`锚点服务单id`,
    f.`10分钟窗口起始时间`,
    MIN(p.`窗口内签到时间`) AS `第一次签到时间`,
    COUNT(DISTINCT p.`窗口内服务单id`) AS `10分钟窗口签到次数`,
    COUNT(DISTINCT p.`窗口内房源ID`)  AS `不同房源数`,
    collect_set(CAST(p.`窗口内房源ID` AS string)) AS `10分钟内签到房源列表`,
    collect_set(CAST(p.`窗口内服务单id` AS string)) AS `10分钟内签到服务单列表`,
    collect_set(date_format(p.`窗口内签到时间`, 'yyyy-MM-dd HH:mm:ss')) AS `10分钟内签到时间列表`
  FROM win_pairs p
  JOIN anchor_grp_id ag
    ON p.`服务者UCID` = ag.`服务者UCID`
   AND p.`锚点服务单id` = ag.`锚点服务单id`
  JOIN anchor_grp_first f
    ON ag.`服务者UCID` = f.`服务者UCID`
   AND ag.anchor_grp_id = f.anchor_grp_id
  GROUP BY ag.`服务者UCID`, ag.anchor_grp_id, f.`锚点服务单id`, f.`10分钟窗口起始时间`
  HAVING COUNT(DISTINCT p.`窗口内服务单id`) >= 3
     AND COUNT(DISTINCT p.`窗口内房源ID`)  >= 3
),
-- 原 t2：先生成原始（多行），再对每个“服务单id”挑一条（去重）
excluded_orders_with_count_raw AS (
  SELECT
    p.`窗口内服务单id` AS `服务单id`,
    gs.`服务者UCID`,
    gs.`10分钟窗口起始时间`,
    gs.`10分钟窗口签到次数`,
    gs.`第一次签到时间`,
    gs.`不同房源数`,
    gs.`10分钟内签到房源列表`,
    gs.`10分钟内签到服务单列表`,
    gs.`10分钟内签到时间列表`,
    gs.`锚点服务单id`
  FROM win_pairs p
  JOIN anchor_grp_id ag
    ON p.`服务者UCID` = ag.`服务者UCID`
   AND p.`锚点服务单id` = ag.`锚点服务单id`
  JOIN group_stats gs
    ON ag.`服务者UCID` = gs.`服务者UCID`
   AND ag.anchor_grp_id = gs.anchor_grp_id
),
excluded_orders_with_count AS (
  SELECT
    t.`服务单id`,
    t.`服务者UCID`,
    t.`10分钟窗口起始时间`,
    t.`10分钟窗口签到次数`,
    t.`第一次签到时间`,
    t.`不同房源数`,
    t.`10分钟内签到房源列表`,
    t.`10分钟内签到服务单列表`,
    t.`10分钟内签到时间列表`,
    t.`锚点服务单id`
  FROM (
    SELECT
      r.*,
      ROW_NUMBER() OVER (
        PARTITION BY r.`服务单id`
        ORDER BY r.`第一次签到时间`, r.`10分钟窗口起始时间`
      ) AS rn
    FROM excluded_orders_with_count_raw r
  ) t
  WHERE rn = 1
),
-- 每个窗口选一个锚点（你原有的逻辑，继续保留）
anchor_per_window AS (
  SELECT
    `服务者UCID`,
    `10分钟窗口起始时间`,
    MIN(`锚点服务单id`) AS `锚点服务单id`
  FROM group_stats
  GROUP BY `服务者UCID`, `10分钟窗口起始时间`
),
-- 主订单来源：按服务单去重，避免 t1 自身重复
main_orders AS (
  SELECT DISTINCT
  manager_marketing_name,
    manager_corp_name,
    city_name,
    service_order_supplier_name,
    service_order_professional_ucid,
    service_order_professional_name,
    first_sign_time,
    house_resource_id,
    service_order_code,
    order_no,
    sign_state,
    pt,
    order_type,
    label_group,
    lease_status
  FROM olap.olap_hj_fas_main_order_service_info_da
  WHERE pt = '${-1d_pt}'
    AND order_type = 16 
    AND label_group NOT IN ('8','1','25') 
    AND lease_status IN (2,3) 
    AND house_resource_id IS NOT NULL 
    AND service_order_code IS NOT NULL
    AND first_sign_time >= '2025-05-01'
)


INSERT OVERWRITE TABLE rpt.rpt_weixiu_abnormal_checkin_list PARTITION (pt='${-1d_pt}')

SELECT DISTINCT
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
  CASE WHEN t2.`服务单id` IS NOT NULL THEN '短时间多次' ELSE '异常距离' END AS `异常签到原因`,
  COALESCE(t2.`第一次签到时间`, t1.first_sign_time) AS `异常签到开始时间`,
  CASE WHEN t2.`服务单id` IS NOT NULL THEN t2.`10分钟窗口签到次数` ELSE 1 END AS `异常签到单量`,
  CASE WHEN t2.`服务单id` IS NOT NULL THEN t2.`不同房源数` ELSE 1 END AS `异常签到房源量`,
  CASE WHEN t2.`服务单id` IS NOT NULL THEN concat_ws(',',t2.`10分钟内签到房源列表`) ELSE CAST(t1.house_resource_id AS string) END AS `异常签到房源列表`,
  CASE WHEN t2.`服务单id` IS NOT NULL THEN concat_ws(',',t2.`10分钟内签到服务单列表`) ELSE CAST(t1.service_order_code AS string) END AS `异常签到服务单列表`,
  CASE WHEN t2.`服务单id` IS NOT NULL THEN concat_ws(',',t2.`10分钟内签到时间列表`) ELSE date_format(t1.first_sign_time, 'yyyy-MM-dd HH:mm') END AS `异常签到服务单时间`,
  t1.manager_marketing_name AS `营销大区/大部`
FROM main_orders t1
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
) b ON t1.order_no = b.oth_orderno
LEFT JOIN excluded_orders_with_count t2
  ON t1.service_order_code = t2.`服务单id`
LEFT JOIN anchor_per_window aw
  ON t2.`服务者UCID` = aw.`服务者UCID`
  AND t2.`10分钟窗口起始时间` = aw.`10分钟窗口起始时间`
LEFT JOIN ( select service_order_code,max(feedback_type) as feedback_type from ods.ods_plat_jiafu_dispatch_service_order_sign_in_feedback_di where pt = '${-1d_pt}' group by service_order_code ) t4
  ON t1.service_order_code = t4.service_order_code
LEFT JOIN ( select service_order_code,max(sign_exception) as sign_exception from ods.ods_plat_jiafu_dispatch_service_order_ext_info_da where pt = '${-1d_pt}' group by service_order_code ) t5
  ON t1.service_order_code = t5.service_order_code
WHERE
  (t2.`不同房源数` >= 3 OR t4.service_order_code IS NOT NULL OR t5.service_order_code IS NOT NULL) 
