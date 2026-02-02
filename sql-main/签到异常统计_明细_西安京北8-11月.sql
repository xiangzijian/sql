-- 签到异常明细查询 - 西安市和惠居京北 8月和11月
-- 用于核对数据

WITH 
-- 主表数据：签到异常单
main_orders AS (
  SELECT DISTINCT
    a.service_order_code,
    a.order_no,
    a.city_name,
    a.manager_marketing_name,
    a.first_sign_time,
    a.sign_state,
    a.service_order_professional_name,
    a.service_order_professional_ucid,
    a.service_order_supplier_name
  FROM olap.olap_hj_fas_main_order_service_info_da a
  INNER JOIN (
    -- 关联轻托管明细表，排除漏水和定损
    SELECT
      order_no AS oth_orderno
    FROM rpt.rpt_fas_light_hosting_order_detail_da
    WHERE pt = '${-1d_pt}'
      AND vison_type = '4.0'
      AND service_name IN ('维修','燃气')
      AND order_type = '16'
      AND label_group NOT IN ('8')  -- 排除检修
      AND commodity_name_list1 != '漏水专项检修'  -- 排除漏水
      AND commodity_name_list1 NOT IN ('夏季空调预检','SCM00300001672373','漏水专项检修','消防器材','定损','漏水定损','火灾定损','其他定损','京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')  -- 排除定损
      AND supplier_name NOT IN ('上海兰宫建筑装饰有限公司','上海尚礼实业有限公司','上海苏皖贸易有限公司','上海再旭保洁服务有限公司','源和里仁家具海安有限公司','匠云（北京）科技有限公司')
  ) b ON a.order_no = b.oth_orderno
  WHERE a.pt = '${-1d_pt}'
    AND a.order_type = 16
    AND a.label_group NOT IN ('8','1','25')  -- 排除检修等
    AND a.lease_status IN (2,3)  -- 租赁状态
    AND a.sign_state = 1  -- 签到异常
    AND a.first_sign_time IS NOT NULL
    -- 筛选8月和11月
    AND SUBSTR(a.first_sign_time, 1, 7) IN ('2025-08', '2025-11')
    -- 筛选西安市和惠居京北
    AND (
      a.city_name = '西安市'
      OR (
        a.city_name = '北京市' 
        AND a.manager_marketing_name IN ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营')
      )
    )
),
-- 人脸识别申诉表
face_appeal_orders AS (
  SELECT DISTINCT
    service_order_code,
    1 AS in_face_appeal
  FROM ods.ods_plat_jiafu_dispatch_service_order_face_appeal_di
  WHERE pt = '${-1d_pt}'
    AND service_order_code IS NOT NULL
),
-- 签到反馈表：获取feedback_type
sign_feedback_orders AS (
  SELECT 
    service_order_code,
    MAX(feedback_type) AS feedback_type
  FROM ods.ods_plat_jiafu_dispatch_service_order_sign_in_feedback_di
  WHERE pt = '${-1d_pt}'
    AND service_order_code IS NOT NULL
  GROUP BY service_order_code
)

-- 最终明细输出
SELECT 
  -- 城市处理
  CASE
    WHEN m.city_name = '北京市' AND m.manager_marketing_name IN ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营')
      THEN '惠居京北'
    ELSE m.city_name
  END AS `城市`,
  SUBSTR(m.first_sign_time, 1, 7) AS `月份`,
  m.service_order_code AS `服务单编码`,
  m.order_no AS `订单号`,
  m.first_sign_time AS `首次签到时间`,
  m.sign_state AS `签到异常标识sign_state`,
  sf.feedback_type AS `签到反馈类型feedback_type`,
  CASE 
    WHEN fa.in_face_appeal = 1 THEN '是' 
    ELSE '否' 
  END AS `是否在人脸识别申诉表`,
  m.service_order_professional_name AS `服务者姓名`,
  m.service_order_professional_ucid AS `服务者UCID`,
  m.service_order_supplier_name AS `供应商`,
  m.manager_marketing_name AS `营销大区`,
  -- 判断是否计入统计（11-14为分界点）
  CASE 
    WHEN m.first_sign_time < '2025-11-14 00:00:00' THEN '计入（11-14前）'
    WHEN m.first_sign_time >= '2025-11-14 00:00:00' 
      AND fa.service_order_code IS NULL 
      AND (sf.feedback_type IS NULL OR sf.feedback_type NOT IN (1, 2))
      THEN '计入（11-14后且未排除）'
    WHEN m.first_sign_time >= '2025-11-14 00:00:00' 
      AND fa.service_order_code IS NOT NULL
      THEN '不计入（人脸识别申诉）'
    WHEN m.first_sign_time >= '2025-11-14 00:00:00' 
      AND sf.feedback_type IN (1, 2)
      THEN '不计入（签到反馈type=1或2）'
    ELSE '不计入（其他）'
  END AS `是否计入统计及原因`
FROM main_orders m
LEFT JOIN face_appeal_orders fa 
  ON m.service_order_code = fa.service_order_code
LEFT JOIN sign_feedback_orders sf 
  ON m.service_order_code = sf.service_order_code
ORDER BY 
  `城市`,
  `月份`,
  m.first_sign_time DESC,
  m.service_order_code
;
