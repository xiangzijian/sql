

SELECT 
   SUBSTR(a.order_create_time, 1, 7) AS month_string,
   a.city_name as `城市`,
    CASE 
        WHEN a.city_name IN ('广州市','深圳市','济南市') AND a.service_order_supplier_name = '上海翊帮人科技有限公司' THEN '上海彼方建筑装饰工程有限公司'
        WHEN a.city_name = '深圳市' AND a.service_order_supplier_name = '云万服（广州）生活服务有限公司' THEN '寰诚建筑（深圳）有限公司'
        ELSE a.service_order_supplier_name 
    END AS `供应商`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        then a.order_no end) as `完工订单数`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        --AND b.order_after_sign_diff_out >= '0' 
        AND (unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24 
        then a.order_no end) as `24h完工订单数`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        --AND b.order_after_sign_diff_out >= '0' 
        AND (unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 48 
        then a.order_no end) as `48h完工订单数`,
    count(distinct case when d.service_order_code is not null then a.order_no end) as `暂不维修订单数`,
    count(distinct case when a.cancel_time IS NOT NULL then a.order_no end) as `取消订单数`,
    count(distinct case when e.accept_status = -1 then a.order_no end) as `未验收`,
    count(distinct case when e.accept_status = 0 then a.order_no end) as `未通过`,
    count(distinct case when e.accept_status = 1 then a.order_no end) as `通过`
 from
   (SELECT  
    manager_marketing_name,
    order_no,max(cancel_time) as cancel_time,
    order_create_time,
    lease_status,
    max(service_order_complete_time) as service_order_complete_time,
    service_order_code,
    service_order_supplier_name,
    label_group,
    max(case
    when city_name = '北京市' and manager_marketing_name in ('京东事业部','京东南事业部','京东南租赁运营部','京东南运营','京东运营','京南事业部','京南大部','京南运营','京西南事业部','京西南运营') then '惠居京南'
    when city_name = '北京市' and manager_marketing_name in ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营') then '惠居京北'
    else city_name
     end) as city_name
    FROM 
    olap.olap_hj_fas_main_order_service_info_da
    where pt = '${-1d_pt}'
    AND order_type = 16
    AND label_group in ('1','25') and 
    substr(order_create_time,1,7)>='2025-01'
    and lease_status IN ('-1','1','2','3') 
    group by order_no,manager_marketing_name,order_create_time,lease_status,service_order_code,service_order_supplier_name,label_group
    ) AS a
    inner join (
     select
     order_no as oth_orderno
     from
    rpt.rpt_fas_light_hosting_order_detail_da
    where pt = '${-1d_pt}'
    and  vison_type='4.0'

    and service_name in ('维修','燃气')
    and order_type='16'
    and label_group not in ( '8')
    and commodity_name_list1!= '漏水专项检修'--2024-12-24
    and commodity_name_list1 not in  ('夏季空调预检','SCM00300001672373','漏水专项检修','消防器材','定损','漏水定损','火灾定损','其他定损','京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')
    and supplier_name not in ('上海兰宫建筑装饰有限公司','上海尚礼实业有限公司','上海苏皖贸易有限公司','上海再旭保洁服务有限公司','源和里仁家具海安有限公司')
    group by order_no
) b on b.oth_orderno=a.order_no
left join ( select distinct service_order_code from rpt.rpt_fas_jiafu_dispatch_service_order_product_da where pt='${-1d_pt}' and reason_code in (104,105,108,101,102,103,106,107,109,110,111,112) 
           )  d on d.service_order_code = a.service_order_code
left join ( select distinct service_order_code,accept_status from ods.ods_plat_jiafu_dispatch_service_order_product_accept_log_da where pt='${-1d_pt}' ) e on e.service_order_code = a.service_order_code

group by SUBSTR(a.order_create_time, 1, 7),
a.city_name,
CASE 
    WHEN a.city_name IN ('广州市','深圳市','济南市') AND a.service_order_supplier_name = '上海翊帮人科技有限公司' THEN '上海彼方建筑装饰工程有限公司'
    WHEN a.city_name = '深圳市' AND a.service_order_supplier_name = '云万服（广州）生活服务有限公司' THEN '寰诚建筑（深圳）有限公司'
    ELSE a.service_order_supplier_name 
END
