insert overwrite table rpt.rpt_jiankandumingxi1 partition (pt='${-1d_pt}')

SELECT 
   a.city_name as `城市`,
   a.bizcircle_name as `商圈`,
   a.resblock_name as `楼盘`,
   a.order_creator_type as `下单角色`,
    CASE 
        WHEN a.city_name IN ('广州市','深圳市','济南市') AND service_order_supplier_name = '上海翊帮人科技有限公司' THEN '上海彼方建筑装饰工程有限公司'
        WHEN a.city_name = '深圳市' AND service_order_supplier_name = '云万服（广州）生活服务有限公司' THEN '寰诚建筑（深圳）有限公司'
        ELSE service_order_supplier_name 
    END AS `供应商`,
    service_order_professional_name AS `服务者姓名`,
    service_order_professional_ucid AS `服务者ucid`,
    a.order_no as `订单号`,
    a.service_order_code as `服务单号`,
    case when kk.`总订单` is null then '否' else '是' end as `是否紧急单`,
    CASE when a.performance_mode=0 THEN '普通单'when a.performance_mode=1 THEN '紧急单'when a.performance_mode=1 THEN '加急单' ELSE  a.performance_mode END AS`紧急单标识`,
    CASE  WHEN a.order_status = 8 THEN '待报价' WHEN a.order_status = 10 THEN '待平台派单' WHEN a.order_status = 20 THEN '待供应商接单'
    WHEN a.order_status = 21 THEN '待供应商派单' WHEN a.order_status = 22 THEN '待服务者接单' WHEN a.order_status = 23 THEN '待服务' WHEN a.order_status = 24 THEN '服务中'
    WHEN a.order_status = 30 THEN '待付款' WHEN a.order_status = 40 THEN '订单完成' WHEN a.order_status = 50 THEN '订单取消' WHEN a.order_status = 11 THEN '成团中'
    ELSE CAST(a.order_status AS STRING) END AS `订单状态`,
    a.order_create_time AS `创建时间`,
    a.first_call_time AS `首次呼叫时间`,
    a.first_sign_time AS `首次签到时间`,
    a.service_order_complete_time AS `完工时间`,
    a.order_complete_time AS `完单时间`,
    a.cancel_time AS `取消时间`,
    case when a.cancel_time >= a.order_create_time and unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')-unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss') <= 3600 then '是' else '否' end as `是否1h取消`,
    case 
    when (a.cancel_time >= a.order_create_time 
          and unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss') <= 3600) 
    then '否'  
    when kk.`紧急30分钟致电单` is not null 
    then '是'  else '否'  
end as `紧急单是否30min致电`,
    CASE WHEN 
             label_group NOT IN ('8') AND lease_status IN (2, 3)
             --AND b.order_after_sign_diff_out >= '0'
              and
              (is_not=1 
        OR (substr(first_call_time,1,4) >='2000' 
            AND (unix_timestamp(first_call_time, 'yyyy-MM-dd HH:mm:ss') 
                 - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60))
        AND (cancel_time = '1000-01-01 00:00:00' 
            OR (unix_timestamp(cancel_time, 'yyyy-MM-dd HH:mm:ss') 
                - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 > 60)
        THEN '是' else '否' END as `非紧急单是否1h致电`,
    case when kk. `2h上门` is null then '否' else '是' end as `紧急单是否2h上门`,
    CASE 
        WHEN first_sign_time IS NOT NULL 
        AND SUBSTR(first_sign_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND label_group NOT IN ('8') 
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0' 
        AND (unix_timestamp(first_sign_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24 
        THEN '是' 
        ELSE '否' 
    END as `非紧急单是否24h上门`,
    CASE 
        WHEN service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND label_group NOT IN ( '8') 
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0' 
        AND (unix_timestamp(service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24 
        THEN '是' 
        ELSE '否'  
    END as `是否24h完工`,
     CASE 
        WHEN order_complete_time IS NOT NULL 
        AND SUBSTR(order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND label_group NOT IN ( '8') 
        AND lease_status IN (2, 3)
        --AND b.order_after_sign_diff_out >= '0' 
        AND (unix_timestamp(order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24 
        THEN '是'  
        ELSE '否'  
    END as `是否24h完单`,
    CASE 
        WHEN is_in5day_complete = 1
        THEN '是' 
        ELSE '否'  
    END as `是否5日完工`,
    CASE WHEN a.service_order_complete_time IS NOT NULL 
        AND substr(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')  -- 完工时间有效
        AND a.first_sign_time IS NOT NULL 
        AND substr(a.first_sign_time, 1, 4) NOT IN ('1990','2050','1000')  -- 签到时间有效
        THEN ROUND((unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss'))  / 3600,2)
        ELSE '0' 
    END AS `工时(小时)`,
    a.check_name_type AS `验收方式`,
    a.user_evaluation_star as `评价星级`,
    SUBSTR(a.order_create_time, 1, 7) AS month_string,
	 a.service_order_status_code as `服务单状态`,
	 CASE WHEN service_order_complete_time IS NOT NULL 
    AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')  
    AND label_group NOT IN ( '8') 
    --AND b.order_after_sign_diff_out >= '0' 
    AND (unix_timestamp(service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 72 
    THEN '是' 
    ELSE '否'  
END as `是否3日完工`,
a.manager_area_name as `业务区域/组`,
a.manager_marketing_name as `营销大区/大部`,
case when label_group in ('1','25') then '检修' when label_group not in ('1','8','25') and lease_status IN ('2','3') then '租后维修' end as `维修类型`,
case when d.service_order_code is not null then '是' else '否' end as `是否暂不维修`,
d.reason as `暂不维修原因`,
e.accept_status as `验收状态`,
e.accept_reason as `验收不通过原因`,
e.operate_type as `操作类型`,
e.operate_name as `操作人姓名`
 from
   (SELECT  
    manager_marketing_name,
    manager_corp_name,
    order_no,max(cancel_time) as cancel_time,
    order_create_time,
    lease_status,
    max(service_order_complete_time) as service_order_complete_time,
    max(first_sign_time) as first_sign_time,
    max(first_call_time) as first_call_time,service_order_code,
    service_order_supplier_name,
    service_order_professional_name,
    service_order_professional_ucid,
    label_group,
    max(order_complete_time) as order_complete_time,
	max(order_status) as order_status,
	max(performance_mode) as performance_mode,
	max(is_in5day_complete) as is_in5day_complete,
	max(check_name_type) as check_name_type,
	max(modified_service_end_time) as modified_service_end_time,
	max(service_start_time) as service_start_time,
	max(user_evaluation_star) as user_evaluation_star,
	max(bizcircle_name) as bizcircle_name,
	max(manager_area_name) as manager_area_name,
	max(resblock_name) as resblock_name,
	max(order_creator_type) as order_creator_type,
    max(case when label_group in ('1','25') then order_no end ) as check_order,
    max(case when label_group not in ('1','8','25') then order_no end ) as zu_order ,
    max(case
    when city_name = '北京市' and manager_marketing_name in ('京东事业部','京东南事业部','京东南租赁运营部','京东南运营','京东运营','京南事业部','京南大部','京南运营','京西南事业部','京西南运营') then '惠居京南'
    when city_name = '北京市' and manager_marketing_name in ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营') then '惠居京北'
    else city_name
     end) as city_name,
	max(service_order_status_code) as service_order_status_code,
    
    max(CASE
  WHEN substr(order_create_time, 12, 2) >= '21'
       AND first_call_time < concat(date_add(to_date(order_create_time), 1), ' 10:00:00')
       AND substr(first_call_time, 1, 4) >= '2000'
  THEN 1
  WHEN substr(order_create_time, 12, 2) < '09'
       AND first_call_time < concat(to_date(order_create_time), ' 10:00:00')
       AND substr(first_call_time, 1, 4) >= '2000'
  THEN 1
  ELSE 0
END )  AS is_not
    FROM 
    olap.olap_hj_fas_main_order_service_info_da
    where pt = '${-1d_pt}'
    AND order_type = 16
    AND label_group NOT IN ('8') and 
    substr(order_create_time,1,7)>='2025-01'
    and lease_status IN ('-1','1','2','3') 
    group by order_no,manager_marketing_name,manager_corp_name,order_create_time,lease_status,service_order_code,service_order_supplier_name,service_order_professional_name,service_order_professional_ucid,label_group
    ) AS a
    inner join (
     select
     order_no as oth_orderno
     ,create_time,max(order_after_sign_diff_out) as order_after_sign_diff_out
    ,max(case when service_time_end>original_service_time_end then service_time_end else original_service_time_end end) as final_time--取预约服务时间和实际服务时间最新的
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
    group by order_no,create_time
) b on b.oth_orderno=a.order_no

left join 
(
  SELECT  
  order_create_time,    order_no as order_no_1,
  max(case when city_name ='北京市' then manager_marketing_name else city_name  end) as `city_name`,
  max(CASE WHEN is_urgent_order =1 OR  is_urgent_switch =1 THEN order_no  END) as `总订单`,
  max( CASE WHEN is_2_hour_urgent_on_door=1 and (is_urgent_order =1 OR  is_urgent_switch =1) then order_no end ) as `2h上门`,
  max( case when is_30_min_urgent_call =1 and ( is_urgent_order =1 OR  is_urgent_switch =1 ) then order_no END ) as `紧急30分钟致电单`
  
FROM rpt.rpt_jiafu_urgent_order_info_da
WHERE pt = '${-1d_pt}'
and substr(order_create_time,1,7)>='2025-01'
and (urgent_flag in  (1,2) or performance_mode in  (1,2))
 group by order_create_time,order_no
)
kk 
on kk.order_no_1 =  a.order_no
left join ( select service_order_code,concat_ws('；', collect_set(reason)) as reason from 
           ( select service_order_code,case when reason_code = 104 then '无法维修,且租客认同暂不处理' 
           when reason_code =105 then '无法维修,且资管确认不做处理' when reason_code =108 then '已确认业主处理' 
           when reason_code =101 then '可正常使用,无需维修' when reason_code =102 then '无法维修且租客希望换新' 
           when reason_code =103 then '重复订单,无需维修' when reason_code =106 then '需其他专业人士维修(如燃气漏气、家具定制)' 
           when reason_code =107 then '需资管确认解决方案(涉及费用分摊)' 
           when reason_code =109 then '已确认物业处理' when reason_code =110 then '已确认资管自行处理'
           when reason_code =111 then '资管已确认不处理(可维修)' when reason_code =112 then '其他' end as reason from rpt.rpt_fas_jiafu_dispatch_service_order_product_da where pt='${-1d_pt}' and reason_code in (104,105,108,101,102,103,106,107,109,110,111,112) 
           ) as t1 group by service_order_code ) d on d.service_order_code = a.service_order_code
left join (
    select service_order_code,accept_status,accept_reason,operate_type,operate_name
    from (
        select service_order_code,accept_status,accept_reason,operate_type,operate_name,
               row_number() over (partition by service_order_code order by operate_time desc) as rn
        from ods.ods_plat_jiafu_dispatch_service_order_product_accept_log_da
        where pt = '${-1d_pt}'
        and operate_type in (3,4)
    ) t
    where rn = 1
) e on e.service_order_code = a.service_order_code
where    label_group NOT IN ('8');
