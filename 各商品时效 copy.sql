WITH base_a AS (
  SELECT DISTINCT
    manager_corp_name,
    order_no,
    order_create_time,
    service_order_complete_time,
    first_sign_time,
    first_call_time,
    service_order_code,
    cancel_time,
    lease_status,
    label_group,
    CASE
      WHEN substr(order_create_time, 12, 2) >= '21'
           AND first_call_time < concat(date_add(to_date(order_create_time), 1), ' 10:00:00')
           AND substr(first_call_time, 1, 4) >= '2000'
      THEN 1
      WHEN substr(order_create_time, 12, 2) < '09'
           AND first_call_time < concat(to_date(order_create_time), ' 10:00:00')
           AND substr(first_call_time, 1, 4) >= '2000'
      THEN 1
      ELSE 0
    END AS is_not
  FROM olap.olap_hj_fas_main_order_service_info_da
  WHERE pt = '20251130000000'
    AND order_type = 16
    AND label_group NOT IN ('8')
),
base_b AS (
  SELECT
    order_no AS oth_orderno,
    create_time,
    order_after_sign_diff_out,
    CASE WHEN service_time_end > original_service_time_end THEN service_time_end ELSE original_service_time_end END AS final_time
  FROM rpt.rpt_fas_light_hosting_order_detail_da
  WHERE pt = '20251130000000'
    AND vison_type = '4.0'
    AND service_name IN ('维修','燃气')
    AND order_type = '16'
    AND label_group NOT IN ('8')                 -- 排除检修
    AND commodity_name_list1 NOT IN ('夏季空调预检','SCM00300001672373','漏水专项检修','消防器材',
                                     '定损','漏水定损','火灾定损','其他定损',
                                     '京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')
    AND supplier_name NOT IN ('上海兰宫建筑装饰有限公司','上海尚礼实业有限公司','上海苏皖贸易有限公司',
                              '上海再旭保洁服务有限公司','源和里仁家具海安有限公司','匠云（北京）科技有限公司')
),
base AS (
  SELECT a.*
  FROM base_a a
  JOIN base_b b
    ON b.oth_orderno = a.order_no
  WHERE a.order_create_time >= '2024-12-01 00:00:00'
    AND a.order_create_time <  '2025-12-01 00:00:00'
)
SELECT
  '全国' AS area,
  '2024-12-01' AS start_date,
  '2025-11-30' AS end_date,
  COUNT(DISTINCT CASE
    WHEN base.service_order_complete_time IS NOT NULL
      AND substr(base.service_order_complete_time,1,4) NOT IN ('1990','2050','1000')
      AND base.label_group NOT IN ('1','8','25')
      AND base.lease_status IN (2,3)
      AND (unix_timestamp(base.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(base.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24
    THEN base.order_no END) AS fixfin24_num,         -- 24h完工量
  COUNT(DISTINCT CASE
    WHEN base.first_sign_time IS NOT NULL
      AND substr(base.first_sign_time,1,4) NOT IN ('1990','2050','1000')
      AND base.label_group NOT IN ('1','8','25')
      AND base.lease_status IN (2,3)
      AND (unix_timestamp(base.first_sign_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(base.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24
    THEN base.order_no END) AS fixdoor24_num,        -- 24h上门量
  COUNT(DISTINCT CASE
    WHEN base.label_group NOT IN ('1','8','25')
      AND base.lease_status IN (2,3)
      AND (
            base.is_not = 1
            OR (
                 substr(base.first_call_time,1,4) >= '2000'
                 AND (unix_timestamp(base.first_call_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(base.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60
               )
          )
      AND (
            base.cancel_time = '1000-01-01 00:00:00'
            OR (unix_timestamp(base.cancel_time,'yyyy-MM-dd HH:mm:ss') - unix_timestamp(base.order_create_time,'yyyy-MM-dd HH:mm:ss')) / 60 > 60
          )
    THEN base.order_no END) AS onehour_connect,      -- 1小时内首联单量
  COUNT(DISTINCT CASE
    WHEN base.label_group NOT IN ('1','8','25')
      AND base.lease_status IN (2,3)
    THEN base.order_no END) AS totalfix_num,         -- 维修总单量
  COUNT(DISTINCT CASE
    WHEN base.label_group NOT IN ('1','8','25')
      AND base.lease_status IN (2,3)
      AND (
            base.cancel_time = '1000-01-01 00:00:00'
            OR (unix_timestamp(base.cancel_time,'yyyy-MM-dd HH:mm:ss') - unix_timestamp(base.order_create_time,'yyyy-MM-dd HH:mm:ss')) / 60 > 60
          )
    THEN base.order_no END) AS onehour               -- 1h取消量分母
FROM base