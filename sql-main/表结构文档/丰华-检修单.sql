WITH 
-- 关联检修单归属表，获取家服订单编码
task_with_order_code AS (
  SELECT DISTINCT
    t.task_id,
    t.property_code,
    d.order_code
  FROM olap.olap_trusteeship_hdel_delivery_examine_task_da t
  LEFT JOIN olap.olap_trusteeship_hdel_examine_divide_da d
    ON t.property_code = d.property_code
    AND t.city_name = d.city_name
    AND d.pt = '20260131000000'
  WHERE t.pt = '20260131000000'
    AND t.city_name = '北京市'
    AND t.task_type = '检修'
    AND (
      (t.task_status <> 5)
      OR (t.task_status = 5 AND t.task_cancel_reason IN ('任务已超期', '新任务生成', '租客已入住'))
    )
    AND (
      substring(t.property_create_time, 1, 7) = '2026-01'
      OR substring(t.property_submit_time, 1, 7) = '2026-01'
    )
),

-- 关联家服订单表，获取维修综合单号
task_with_repair_order AS (
  SELECT 
    tc.task_id,
    tc.property_code,
    o.order_no
  FROM task_with_order_code tc
  LEFT JOIN olap.olap_hj_fas_main_order_service_info_da o
    ON tc.order_code = o.order_no
    AND o.pt = '20260131000000'
    AND o.professional_tag_category IS NOT NULL
    AND o.professional_tag_category LIKE '%维修综合%'
),

t1 AS (
  SELECT DISTINCT 
    t.city_name,
    t.manager_corp_name,
    CASE 
      WHEN t.city_name = '北京市' AND t.manager_corp_name IN ('惠居京南', '惠居京北') 
      THEN t.manager_corp_name 
      ELSE t.city_name 
    END AS `城市`,
    t.task_id,
    t.task_type AS `任务类型`,
    t.houseinout_type,
    t.biz_type,
    CASE 
      WHEN t.biz_type = 1 THEN '签约' 
      WHEN t.biz_type = 2 THEN '解约' 
      ELSE NULL 
    END AS `签约or解约`,
    t.current_deal_employee_job_name AS `当前处理人岗位`,
    t.manager_area_name AS `资管业务区域/组名称`,
    t.current_deal1_employee_ucid AS `当前处理人ucid（服务者）`,
    t.current_deal1_employee_name AS `当前处理人姓名（服务者）`,
    t.task_create_time AS `任务创建时间（系统派发）`,
    substring(t.task_create_time, 1, 7) AS `任务派发月份`,
    t.task_follow_time AS `任务跟进时间`,
    t.task_finish_time AS `任务完成时间`,
    t.task_cancel_time AS `任务取消时间`,
    t.is_task_time AS `是否达到做任务时间`,
    t.task_time,
    t.init_task_time,
    substring(t.task_time, 1, 10) AS `任务应做日期`,
    substring(t.task_time, 1, 7) AS `任务应做月份`,
    t.property_code AS `检修单编码`,
    ro.order_no AS `对应的维修单号`,
    t.property_status,
    t.task_status,
    t.property_create_time AS `检修单创建时间`,
    t.property_submit_time AS `检修单提交时间`,
    t.is_examine_order AS `是否有检修家服订单`,
    substring(t.property_create_time, 1, 7) AS `检修单创建月份`,
    substring(t.property_submit_time, 1, 7) AS `检修单提交月份`,
    t.task_cancel_time AS `取消时间`,
    t.task_cancel_reason AS `取消原因`,
    CASE 
      WHEN t.task_workbench_flag = 1 THEN '取消' 
      WHEN t.task_workbench_flag = 2 THEN '延期' 
      ELSE NULL 
    END AS `手动申请延期或取消`,
    t.task_workbench_reason AS `延期或取消原因`,
    CASE WHEN t.property_submit_time <> '1000-01-01 00:00:00' AND to_date(t.property_submit_time) <= date_add(to_date(t.init_task_time), 1) THEN 1 ELSE 0 END AS `是否T+1天内完成提交_1是(原始)`,
    CASE WHEN t.property_submit_time <> '1000-01-01 00:00:00' AND to_date(t.property_submit_time) <= date_add(to_date(t.init_task_time), 5) THEN 1 ELSE 0 END AS `是否T+5天内完成提交_1是(原始)`,
    t.contract_id AS `合同id`,
    t.contract_code AS `合同编号`,
    t.trusteeship_housedel_code AS `托管房源编码`,
    t.property_employee_ucid AS `处理人ucid`,
    t.property_employee_name AS `检修单处理人姓名`,
    t.pt AS `分区字段`
  FROM olap.olap_trusteeship_hdel_delivery_examine_task_da t
  LEFT JOIN task_with_repair_order ro
    ON t.task_id = ro.task_id
    AND t.property_code = ro.property_code
  WHERE pt = '20260131000000'
    AND city_name = '北京市'  -- 城市=北京市
    AND task_type = '检修'
    -- AND is_task_time = 1
    AND (
      (task_status <> 5)
      OR (task_status = 5 AND task_cancel_reason IN ('任务已超期', '新任务生成', '租客已入住'))
    )
    -- 检修单创建月份或提交月份是2026年1月
    AND (
      substring(property_create_time, 1, 7) = '2026-01'
      OR substring(property_submit_time, 1, 7) = '2026-01'
    )
)

-- 输出明细数据
SELECT 
  t1.`城市`,
  t1.task_id,
  t1.`任务类型`,
  t1.houseinout_type,
  t1.`签约or解约`,
  t1.`当前处理人岗位`,
  t1.`资管业务区域/组名称`,
  t1.`当前处理人ucid（服务者）`,
  t1.`当前处理人姓名（服务者）`,
  t1.`任务创建时间（系统派发）`,
  t1.`任务派发月份`,
  t1.`任务跟进时间`,
  t1.`任务完成时间`,
  t1.`任务取消时间`,
  t1.`是否达到做任务时间`,
  t1.task_time,
  t1.init_task_time,
  t1.`任务应做日期`,
  t1.`任务应做月份`,
  t1.`检修单编码`,
  t1.`对应的维修单号`,
  t1.property_status,
  t1.task_status,
  t1.`检修单创建时间`,
  t1.`检修单提交时间`,
  t1.`检修单创建月份`,
  t1.`检修单提交月份`,
  t1.`取消时间`,
  t1.`取消原因`,
  t1.`手动申请延期或取消`,
  t1.`延期或取消原因`,
  t1.`是否T+1天内完成提交_1是(原始)`,
  t1.`是否T+5天内完成提交_1是(原始)`,
  t1.`合同id`,
  t1.`合同编号`,
  t1.`托管房源编码`,
  t1.`处理人ucid`,
  t1.`检修单处理人姓名`,
  t1.`是否有检修家服订单`,
  t1.`分区字段`
FROM t1
ORDER BY t1.`检修单提交时间`, t1.`检修单编码`
