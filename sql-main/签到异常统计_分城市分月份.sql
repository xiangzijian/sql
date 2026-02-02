-- 分城市分月份统计签到异常服务单编码
-- 2025年11月14日前后分别处理
-- 11月14日之后的需排除人脸识别申诉和签到反馈表
-- 参考健康度.sql，排除漏水和定损

WITH numbers AS (
    SELECT
        CONCAT(year_string, '-', LPAD(n, 2, '0')) AS month_string,
        city_name
    FROM
        (SELECT n, city_name, year_string
         FROM
           (SELECT stack(12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) AS n) t1  
         LATERAL VIEW EXPLODE(
           ARRAY('上海市', '天津市', '成都市', '杭州市', '苏州市', '宁波市', '深圳市', '济南市', '广州市', '西安市', '武汉市', '南京市','惠居京北','惠居京南')
         ) t2 AS city_name
         LATERAL VIEW EXPLODE(
           ARRAY('2025', '2026')
         ) t3 AS year_string
        ) t
),
-- 主表数据：签到异常单
main_orders AS (
  SELECT DISTINCT
    a.service_order_code,
    a.order_no,
    a.city_name,
    a.manager_marketing_name,
    a.first_sign_time,
    a.sign_state
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
    -- 不限制月份，统计所有时间的数据
),
-- 人脸识别申诉表：需要排除的服务单
face_appeal_orders AS (
  SELECT DISTINCT
    service_order_code
  FROM ods.ods_plat_jiafu_dispatch_service_order_face_appeal_di
  WHERE pt = '${-1d_pt}'
    AND service_order_code IS NOT NULL
),
-- 签到反馈表：feedback_type=1或2需要排除的服务单
sign_feedback_orders AS (
  SELECT DISTINCT
    service_order_code
  FROM ods.ods_plat_jiafu_dispatch_service_order_sign_in_feedback_di
  WHERE pt = '${-1d_pt}'
    AND service_order_code IS NOT NULL
    AND feedback_type IN (1, 2)
),
-- 处理城市字段（北京市拆分为京北和京南）
processed_orders AS (
  SELECT
    CASE
      WHEN m.city_name = '北京市' AND m.manager_marketing_name IN ('京东事业部','京东南事业部','京东南租赁运营部','京东南运营','京东运营','京南事业部','京南大部','京南运营','京西南事业部','京西南运营') 
        THEN '惠居京南'
      WHEN m.city_name = '北京市' AND m.manager_marketing_name IN ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营')
        THEN '惠居京北'
      ELSE m.city_name
    END AS city_name,
    m.service_order_code,
    SUBSTR(m.first_sign_time, 1, 7) AS order_month,
    m.first_sign_time,
    -- 根据时间判断是否排除
    CASE 
      -- 11月14日之前的签到异常，直接统计
      WHEN m.first_sign_time < '2025-11-14 00:00:00' THEN 1
      -- 11月14日之后的签到异常，需要排除人脸识别申诉和签到反馈
      WHEN m.first_sign_time >= '2025-11-14 00:00:00' 
        AND fa.service_order_code IS NULL  -- 不在人脸识别申诉表中
        AND sf.service_order_code IS NULL  -- 不在签到反馈表中（feedback_type=1或2）
        THEN 1
      ELSE 0
    END AS is_valid
  FROM main_orders m
  LEFT JOIN face_appeal_orders fa ON m.service_order_code = fa.service_order_code
  LEFT JOIN sign_feedback_orders sf ON m.service_order_code = sf.service_order_code
)

-- 最终统计结果
SELECT 
  numbers.city_name AS `城市`,
  numbers.month_string AS `月份`,
  COUNT(DISTINCT CASE 
    WHEN po.order_month = numbers.month_string 
      AND po.is_valid = 1 
    THEN po.service_order_code 
  END) AS `签到异常服务单数`
FROM numbers
LEFT JOIN processed_orders po
  ON numbers.city_name = po.city_name
WHERE numbers.month_string <= SUBSTR(CURRENT_DATE, 1, 7)  -- 只统计到当前月份
  -- 不限制起始月份，统计所有时间的数据
GROUP BY 
  numbers.city_name,
  numbers.month_string
ORDER BY 
  numbers.month_string,
  numbers.city_name
;
