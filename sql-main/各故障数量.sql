SELECT
    city_name,
    SUBSTR(create_time, 1, 7)     AS month_no,        -- 1-12 月
    commodity_name,
    fault_desc_ext,
    function_name,
    COUNT(DISTINCT order_no)        AS order_cnt        -- 统计订单数
FROM  
  ( 
  select DISTINCT order_no,create_time,commodity_name,fault_desc_ext,function_name,city_name
  from  olap.olap_hj_fas_main_order_commodity_da 
  WHERE pt = '${-1d_pt}'   and  fault_desc_ext is not null   
  and label_group in ('1','25') 
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

GROUP BY
   SUBSTR(create_time, 1, 7),
    commodity_name,
    fault_desc_ext,
    function_name,
    city_name
