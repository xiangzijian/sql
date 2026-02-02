-- 健康度总表 - 仅筛选漏水和定损
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
sign_details AS (
  SELECT
    service_order_professional_ucid AS `服务者UCID`,
    first_sign_time AS `签到时间`,
    unix_timestamp(first_sign_time) AS ts,   -- 秒级时间戳
    house_resource_id AS `房源ID`,
    order_no AS `服务单号`
  FROM (
    SELECT DISTINCT
      service_order_professional_ucid,
      first_sign_time,
      house_resource_id,
      order_no
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
    a.`服务单号` AS `锚点服务单号`,
    a.`签到时间` AS `窗口锚点时间`,
    a.ts AS anchor_ts,
    b.`服务单号` AS `窗口内服务单号`,
    b.`签到时间` AS `窗口内签到时间`,
    b.`房源ID` AS `窗口内房源ID`
  FROM sign_details a
  JOIN sign_details b
    ON a.`服务者UCID` = b.`服务者UCID`
  WHERE b.ts >= a.ts
    AND b.ts <= a.ts + 600
),
window_stats AS (
  SELECT
    `服务者UCID`,
    `锚点服务单号`,
    `窗口锚点时间` AS `10分钟窗口起始时间`,
    anchor_ts,
    MIN(`窗口内签到时间`) AS `第一次签到时间`,
    COUNT(DISTINCT `窗口内服务单号`) AS `10分钟窗口签到次数`,
    COUNT(DISTINCT `窗口内房源ID`)  AS `不同房源数`
  FROM win_pairs
  GROUP BY `服务者UCID`, `锚点服务单号`, `窗口锚点时间`, anchor_ts
  HAVING COUNT(DISTINCT `窗口内服务单号`) >= 3
     AND COUNT(DISTINCT `窗口内房源ID`)  >= 3
),
excluded_orders_with_count AS (
  SELECT
  distinct
    p.`窗口内服务单号` AS `服务单号`
  FROM win_pairs p
  JOIN window_stats v
    ON p.`服务者UCID` = v.`服务者UCID`
   AND p.`锚点服务单号` = v.`锚点服务单号`
)

insert overwrite table rpt.rpt_jiankang_test partition (pt='${-1d_pt}')

SELECT
   a.city_name,
    SUBSTR(numbers.month_string, 1, 7) AS month_string,
    CASE
        WHEN numbers.city_name IN ('广州市','深圳市','济南市') AND service_order_supplier_name = '上海翊帮人科技有限公司' THEN '上海彼方建筑装饰工程有限公司'
        WHEN numbers.city_name = '深圳市' AND service_order_supplier_name = '云万服（广州）生活服务有限公司' THEN '寰诚建筑（深圳）有限公司'
        ELSE service_order_supplier_name
    END AS `供应商`,
    service_order_professional_name AS `服务者姓名`,
    service_order_professional_ucid AS `服务者ucid`,
    COUNT(DISTINCT CASE
        WHEN SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND service_order_complete_time IS NOT NULL
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND label_group NOT IN ('1', '8','25')
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0'
        AND (unix_timestamp(service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24
        THEN order_no
        ELSE NULL
    END) AS fixfin24_num,
    COUNT(DISTINCT CASE
        WHEN SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND first_sign_time IS NOT NULL
        AND SUBSTR(first_sign_time, 1, 4) NOT IN ('1990','2050','1000')
        AND label_group NOT IN ('1', '8','25')
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0'
        AND (unix_timestamp(first_sign_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24
        THEN order_no
        ELSE NULL
    END) AS fixdoor24_num,
    COUNT(DISTINCT CASE
        WHEN SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND order_complete_time IS NOT NULL
        AND SUBSTR(order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND label_group NOT IN ('1', '8','25')
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0'
        AND (unix_timestamp(order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24
        THEN order_no
        ELSE NULL
    END) AS fix24_num,
   COUNT(DISTINCT CASE WHEN
              SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
          and label_group NOT IN ('1', '8','25')
          AND lease_status IN (2, 3)
          --AND b.order_after_sign_diff_out >= '0'
              and
              (is_not=1
        OR (substr(first_call_time,1,4) >='2000'
            AND (unix_timestamp(first_call_time, 'yyyy-MM-dd HH:mm:ss')
                 - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60))
        AND (cancel_time = '1000-01-01 00:00:00'
            OR (unix_timestamp(cancel_time, 'yyyy-MM-dd HH:mm:ss')
                - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 > 60)


        THEN order_no END) AS onehour_connect  ,


    COUNT(DISTINCT CASE
        WHEN SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND label_group NOT IN ('1', '8','25')
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0'
        THEN order_no
    END) AS totalfix_num,
    COUNT(DISTINCT CASE
        WHEN SUBSTR(b.final_time, 1, 7) = SUBSTR(numbers.month_string, 1, 7)
        AND SUBSTR(b.final_time, 1, 10) <= substr('${-1d_yyyy-MM-dd}',1,10)
        AND label_group NOT IN ('1', '8','25')
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0'
        AND later_under_num = 1
        THEN a.service_order_code
    END) AS later_under_num,
    COUNT(DISTINCT CASE
        WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(b.final_time, 1, 7)
        AND SUBSTR(b.final_time, 1, 10) <= substr('${-1d_yyyy-MM-dd}',1,10)
        AND label_group NOT IN ('1', '8','25')
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0'
        AND a.service_order_code = a.service_order_code
        AND change = 1
        THEN a.service_order_code
    END) AS un_customer_num,
    COUNT(DISTINCT CASE
        WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(b.final_time, 1, 7)
        AND SUBSTR(b.final_time, 1, 10) <= substr('${-1d_yyyy-MM-dd}',1,10)
        AND label_group NOT IN ('1', '8','25')
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0'
        AND a.service_order_code = a.service_order_code
        AND later_num = 1
        THEN a.service_order_code
    END) AS later_order_no_num,
   COUNT(DISTINCT CASE
     WHEN SUBSTR(a.service_order_complete_time, 1, 7) = DATE_FORMAT(
         ADD_MONTHS(TO_DATE(CONCAT(numbers.month_string, '-01')), -1),
         'yyyy-MM'
     )
     THEN CONCAT(d.product_code, '-', a.order_no)
     ELSE NULL
   END) AS `返修分母`,
COUNT(DISTINCT CASE
     WHEN SUBSTR(a.service_order_complete_time, 1, 7) = DATE_FORMAT(
         ADD_MONTHS(TO_DATE(CONCAT(numbers.month_string, '-01')), -1),
         'yyyy-MM'
     )
     THEN CONCAT(d.product_code, '-', a.check_order)
     ELSE NULL
   END) AS `返修分母-检修`,
   COUNT(DISTINCT CASE
     WHEN SUBSTR(a.service_order_complete_time, 1, 7) = DATE_FORMAT(
         ADD_MONTHS(TO_DATE(CONCAT(numbers.month_string, '-01')), -1),
         'yyyy-MM'
     ) AND lease_status IN (2, 3)
     --AND b.order_after_sign_diff_out >= '0'
     THEN CONCAT(d.product_code, '-', a.zu_order)
     ELSE NULL
   END) AS `返修分母-租后维修`,
   -- 分子：上月完工订单在后续出现的返修记录

  COUNT( distinct  CASE
     WHEN SUBSTR(a.service_order_complete_time, 1, 7) = DATE_FORMAT(
         ADD_MONTHS(TO_DATE(CONCAT(numbers.month_string, '-01')), -1),
         'yyyy-MM'
     )
     AND f.`返修单号` IS NOT NULL
     THEN CONCAT(d.product_code, '-', a.order_no)
     ELSE NULL
   END) AS `返修分子1`,
    COUNT( distinct  CASE
     WHEN SUBSTR(a.service_order_complete_time, 1, 7) = DATE_FORMAT(
         ADD_MONTHS(TO_DATE(CONCAT(numbers.month_string, '-01')), -1),
         'yyyy-MM'
     )
     AND f.`返修单号` IS NOT NULL
     THEN CONCAT(d.product_code, '-', a.check_order)
     ELSE NULL
   END) AS `返修分子-检修`,
    COUNT( distinct  CASE
     WHEN SUBSTR(a.service_order_complete_time, 1, 7) = DATE_FORMAT(
         ADD_MONTHS(TO_DATE(CONCAT(numbers.month_string, '-01')), -1),
         'yyyy-MM'
     ) AND lease_status IN (2, 3)
     --AND b.order_after_sign_diff_out >= '0'
     AND f.`返修单号` IS NOT NULL
     THEN CONCAT(d.product_code, '-', a.zu_order)
     ELSE NULL
   END) AS `返修分子-租后维修`,
    COUNT(DISTINCT CASE
    WHEN a.label_group NOT IN ('1', '8', '25') and  SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
    AND lease_status IN (2, 3)
    --AND b.order_after_sign_diff_out >= 0
    AND (a.cancel_time = '1000-01-01 00:00:00'  -- 未取消订单
         OR (unix_timestamp(a.cancel_time,'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time,'yyyy-MM-dd HH:mm:ss')) / 60 > 60)  -- 或取消时间超过60分钟
    THEN a.order_no
END) AS `总维修订单数据-取消分母`,
     count (distinct case when  SUBSTR(numbers.month_string, 1, 7) = substr(kk.order_create_time,1,7) then kk. `总订单` end ) as `紧急单分母`,
     count (distinct case when  SUBSTR(numbers.month_string, 1, 7) = substr(kk.order_create_time,1,7) then kk. `2h上门` end ) as `紧急单分子`,
     count (distinct case when  SUBSTR(numbers.month_string, 1, 7) = substr(kk.order_create_time,1,7) AND (a.cancel_time = '1000-01-01 00:00:00' OR (unix_timestamp(a.cancel_time,'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time,'yyyy-MM-dd HH:mm:ss')) / 60 > 60) then kk. `紧急30分钟致电单` end ) as `紧急单-致电率分子`,
     count( distinct case when  SUBSTR(numbers.month_string, 1, 7) = substr(a.first_sign_time,1 , 7) and tt1.`10分钟窗口签到次数` is not null then tt1.order_no_2 end) as `10分钟异常签到分子`,
     count( distinct case when  SUBSTR(numbers.month_string, 1, 7) = substr(a.first_sign_time,1 , 7) then tt1.e_order end) as `异地签到分子`,
     count( distinct case when  SUBSTR(numbers.month_string, 1, 7) = substr(a.first_sign_time,1 , 7) then tt1.order_no_2 end) as `异常签到分母`,
     count (distinct case when  SUBSTR(numbers.month_string, 1, 7) = substr(kk.order_create_time,1,7) AND (a.cancel_time = '1000-01-01 00:00:00' OR (unix_timestamp(a.cancel_time,'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time,'yyyy-MM-dd HH:mm:ss')) / 60 > 60) then kk. `总订单` end ) as `紧急单分母剔1h取消`
FROM numbers
LEFT JOIN
   (SELECT DISTINCT
    manager_corp_name,
    order_no,cancel_time,
    order_create_time,
    service_order_complete_time,
    first_sign_time,
    first_call_time,service_order_code,
    service_order_supplier_name,
    service_order_professional_name,
    service_order_professional_ucid,
    lease_status,
    label_group,
    order_complete_time,
    case when label_group in ('1','25') OR lease_status IN ('-1','1') then order_no end as check_order,
    case when label_group not in ('1','8','25') then order_no end as zu_order ,
    case
    when city_name = '北京市' and manager_marketing_name in ('京东事业部','京东南事业部','京东南租赁运营部','京东南运营','京东运营','京南事业部','京南大部','京南运营','京西南事业部','京西南运营') then '惠居京南'
    when city_name = '北京市' and manager_marketing_name in ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营') then '惠居京北'
    else city_name
     end as city_name ,

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
    FROM
    olap.olap_hj_fas_main_order_service_info_da
    where pt = '${-1d_pt}'
    AND order_type = 16
    AND label_group NOT IN ('8')
    ) AS a
     on numbers.city_name=a.city_name
    inner join (
     select
     order_no as oth_orderno
     ,create_time,order_after_sign_diff_out
    ,case when service_time_end>original_service_time_end then service_time_end else original_service_time_end end as final_time--取预约服务时间和实际服务时间最新的
     from
    rpt.rpt_fas_light_hosting_order_detail_da
    where pt = '${-1d_pt}'
    and  vison_type='4.0'
    and label_group not in ( '8')
    -- 新的筛选条件：只保留漏水和定损，如果同时包含算在定损上
    and (
        (commodity_name_list1 like '%漏水%' and commodity_name_list1 not like '%定损%') OR
        (commodity_name_list1 like '%定损%')
    )
    and supplier_name not in ('上海兰宫建筑装饰有限公司','上海尚礼实业有限公司','上海苏皖贸易有限公司','上海再旭保洁服务有限公司','源和里仁家具海安有限公司','匠云（北京）科技有限公司')
) b on b.oth_orderno=a.order_no

left join (
  select
  distinct
  service_order_code
  ,change-- 改约
  ,later_num--迟到
  ,all_under_num as later_under_num
  from
  rpt.rpt_customer_fix_manager_da
  where pt='${-1d_pt}'
)c on a.service_order_code=c.service_order_code

-- 这个是6项商品数据
left join
( select distinct
       c.service_order_code
       ,c.product_name
       ,c.product_code
     from
     dw.dw_fas_jiafu_dispatch_service_order_product_da c
     where pt='${-1d_pt}'
    
        )  d on d.service_order_code = a .service_order_code
LEFT JOIN (
    SELECT
        n.`返修单号`,
        n.`关联单号`,
        n.`返修时间`,
        n.`返修商品`,
        n.`返修商品名称`
    FROM (
        SELECT
            r.order_code AS `返修单号`,
            r.relate_order_code AS `关联单号`,
            r.order_create_date AS `返修时间`,
            g.commodity_code AS `返修商品`,
            g.commodity_name AS `返修商品名称`,
            ROW_NUMBER() OVER(
                PARTITION BY r.relate_order_code, g.commodity_name
                ORDER BY r.order_create_date
            ) AS rn
        FROM (
            SELECT
                order_code,
                relate_order_code,
                order_create_date
            FROM rpt.rpt_plat_beijia_transaction_trade_order_relate_info_di
            WHERE pt BETWEEN '20250301000000' AND '${-1d_pt}'
            AND relate_type = '1'
            AND del_status = '1'
        ) r
        JOIN (
            SELECT
                order_no,
                commodity_code,
                commodity_name
            FROM olap.olap_hj_fas_main_order_commodity_da
            WHERE pt = '${-1d_pt}'
            AND commodity_type = 1
        
           --  AND manager_corp_name = '惠居京北'
        ) g ON g.order_no = r.order_code
    ) n
    WHERE n.rn = 1
) f ON a.order_no = f.`关联单号` AND d.product_code = f.`返修商品`
left join
(
  SELECT distinct
  order_create_time,    order_no as order_no_1,
  case when city_name ='北京市' then manager_corp_name else city_name  end as `city_name`,
 CASE WHEN is_urgent_order =1 OR  is_urgent_switch =1 THEN order_no  END as `总订单`,
 CASE WHEN is_2_hour_urgent_on_door=1 and (is_urgent_order =1 OR  is_urgent_switch =1) then order_no end as `2h上门`,
 case when is_30_min_urgent_call =1 and ( is_urgent_order =1 OR  is_urgent_switch =1 ) then order_no END as `紧急30分钟致电单`

FROM rpt.rpt_jiafu_urgent_order_info_da
WHERE pt = '${-1d_pt}'
-- and manager_corp_name = '惠居京北'
and substr(order_create_time,1,7)>='2025-01'
and (urgent_flag in  (1,2) or performance_mode in  (1,2))
)
kk
on kk.order_no_1 =  a.order_no
left join (
    SELECT
    main.order_no as order_no_2,
    max(IF(feedback.feedback_type = 1 OR ext_info.sign_exception = 1, main.order_no, NULL)) AS e_order,
    max(eowc.`服务单号`) AS `10分钟窗口签到次数`
FROM
    olap.olap_hj_fas_main_order_service_info_da main
LEFT JOIN excluded_orders_with_count eowc
    ON main.order_no = eowc.`服务单号`
    LEFT JOIN ( select service_order_code,max(feedback_type) as feedback_type from ods.ods_plat_jiafu_dispatch_service_order_sign_in_feedback_di where pt = '${-1d_pt}' group by service_order_code) feedback
        ON main.service_order_code = feedback.service_order_code
    LEFT JOIN ( select service_order_code,max(sign_exception) as sign_exception from ods.ods_plat_jiafu_dispatch_service_order_ext_info_da where pt = '${-1d_pt}' group by service_order_code) ext_info
        ON main.service_order_code = ext_info.service_order_code
WHERE
    main.pt = '${-1d_pt}'
    AND main.order_type = 16
    AND main.label_group NOT IN ('8', '1', '25')
    AND main.lease_status IN (2, 3)
    AND main.house_resource_id IS NOT NULL
    AND main.order_no IS NOT NULL
    group by main.order_no
 )  tt1 on tt1.order_no_2 =  a.order_no
 where numbers.month_string <= substr(current_date,1,7)
 GROUP BY a.city_name,substr(numbers.month_string, 1, 7),
 case when numbers.city_name in ('广州市','深圳市','济南市') and service_order_supplier_name='上海翊帮人科技有限公司'   then '上海彼方建筑装饰工程有限公司'
    when  numbers.city_name ='深圳市' and service_order_supplier_name='云万服（广州）生活服务有限公司' then '寰诚建筑（深圳）有限公司'
    else service_order_supplier_name end,
  service_order_professional_name,service_order_professional_ucid
