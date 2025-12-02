SELECT   -- 1-12 月
    commodity_name,
    COUNT(DISTINCT CASE WHEN 
             label_group NOT IN ('1', '8','25') 
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
        WHEN first_sign_time IS NOT NULL 
        AND SUBSTR(first_sign_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND label_group NOT IN ('1', '8','25') 
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0' 
        AND (unix_timestamp(first_sign_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24 
        THEN order_no 
        ELSE NULL 
    END) AS fixdoor24_num,
    COUNT(DISTINCT CASE 
        WHEN  order_complete_time IS NOT NULL 
        AND SUBSTR(order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND label_group NOT IN ('1', '8','25') 
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0' 
        AND (unix_timestamp(order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24 
        THEN order_no 
        ELSE NULL 
    END) AS fix24_num,
     COUNT(DISTINCT CASE 
        WHEN  label_group NOT IN ('1', '8','25') 
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0' 
        THEN order_no 
    END) AS totalfix_num,
    COUNT(DISTINCT t1.order_no)        AS order_cnt        -- 统计订单数
FROM  
  ( 
  select DISTINCT order_no,create_time,commodity_name,fault_desc_ext,function_name,city_name,label_group
  from  olap.olap_hj_fas_main_order_commodity_da 
  WHERE pt = '${-1d_pt}'   and  fault_desc_ext is not null   
  ) t1 
  inner join 
  (
     select
      DISTINCT order_no as oth_orderno
     from
    rpt.rpt_fas_light_hosting_order_detail_da
    where pt = '${-1d_pt}'
    and  vison_type='4.0'
    and service_name in ('维修','燃气')
    and order_type='16'
    and commodity_name_list1!= '漏水专项检修'--2024-12-24漏水coe剔除
    and commodity_name_list1 not in  ('夏季空调预检','SCM00300001672373','漏水专项检修','消防器材','定损','漏水定损','火灾定损','其他定损','京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')
    and supplier_name not in ('上海兰宫建筑装饰有限公司','上海尚礼实业有限公司','上海苏皖贸易有限公司','上海再旭保洁服务有限公司','源和里仁家具海安有限公司','匠云（北京）科技有限公司')
  ) t2
on t1.order_no=t2.oth_orderno
 LEFT JOIN (SELECT DISTINCT 
    order_no,cancel_time,
    order_create_time,
    first_sign_time,
    first_call_time,
    lease_status,
    order_complete_time,
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
on t1.order_no=a.order_no
GROUP BY
    commodity_name
