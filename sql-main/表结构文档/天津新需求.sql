SELECT 
   SUBSTR(a.service_order_complete_time, 1, 7) AS month_string,
   a.city_name as `城市`,
   a.service_order_supplier_name as `供应商名称`,
    count(distinct case when a.service_order_complete_time IS NOT NULL
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        then a.order_no end) as `当月完工的检修单数`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND d.service_order_code is not null 
        then a.order_no end) as `完工检修单中暂不维修数`,
    count(distinct case when a.order_status = 50 then a.order_no end) as `订单状态为50的取消订单数`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND (unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24
        then a.order_no end) as `当月完工订单中24小时完工数`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND (unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 48
        then a.order_no end) as `当月完工订单中48小时完工数`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND e.accept_status = -1 
        then a.order_no end) as `未验收数`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND e.accept_status = 0 
        then a.order_no end) as `未通过数`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND e.accept_status = 1 
        then a.order_no end) as `通过数`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND f.reject_to_reinitiate_hours <= 24 
        then a.order_no end) as `验收驳回后24h内重新发起验收订单数`,
    count(distinct case when a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND f.reject_to_reinitiate_hours <= 48 
        then a.order_no end) as `验收驳回后48h内重新发起验收订单数`
 from
   (SELECT  
    manager_marketing_name,
    order_no,max(cancel_time) as cancel_time,
    order_create_time,
    lease_status,
    order_status,
    max(service_order_complete_time) as service_order_complete_time,
    service_order_code,
    service_order_supplier_name,
    label_group,
    max(city_name) as city_name
    FROM 
    olap.olap_hj_fas_main_order_service_info_da
    where pt = '${-1d_pt}'
    AND order_type = 16
    AND label_group in ('1','25') and 
    substr(service_order_complete_time,1,7)>='2025-01'
    AND service_order_complete_time IS NOT NULL
    AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
    and lease_status IN ('-1','1','2','3') 
    group by order_no,manager_marketing_name,order_create_time,lease_status,order_status,service_order_code,service_order_supplier_name,label_group
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
left join ( 
    select t.service_order_code, t.accept_status 
    from (
        select service_order_code, accept_status, operate_time as accept_operate_time,
               row_number() over(partition by service_order_code order by operate_time desc) as rn
        from ods.ods_plat_jiafu_dispatch_service_order_product_accept_log_da 
        where pt='${-1d_pt}'
    ) t
    where t.rn = 1
) e on e.service_order_code = a.service_order_code
left join (
    -- 计算订单驳回后重新发起验收的时间间隔（小时）
    select 
        service_order_code,
        min((unix_timestamp(reinitiate_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(reject_time, 'yyyy-MM-dd HH:mm:ss')) / 3600) as reject_to_reinitiate_hours
    from (
        select
            x.service_order_code,
            x.reject_ot as reject_time,
            x.reinitiate_ot as reinitiate_time,
            row_number() over (
                partition by x.service_order_code, x.reject_ot
                order by x.reinitiate_ot asc
            ) as rn
        from (
            select
                r.service_order_code,
                r.reject_ot,
                i.reinitiate_ot
            from (
                select
                    service_order_code,
                    operate_time as reject_ot
                from ods.ods_plat_jiafu_dispatch_service_order_product_accept_log_da
                where pt = '${-1d_pt}'
                  and operate_type = 3  -- 验收驳回
            ) r
            inner join (
                select
                    service_order_code,
                    operate_time as reinitiate_ot
                from ods.ods_plat_jiafu_dispatch_service_order_product_accept_log_da
                where pt = '${-1d_pt}'
                  and operate_type = 2  -- 重新发起验收
            ) i
              on r.service_order_code = i.service_order_code
            where i.reinitiate_ot > r.reject_ot  -- 重新发起在驳回之后（避免写在 ON 里触发 Hive 歧义报错）
        ) x
    ) temp
    where rn = 1  -- 每次驳回后的第一次重新发起
    group by service_order_code
) f on f.service_order_code = a.service_order_code

group by SUBSTR(a.service_order_complete_time, 1, 7),
a.city_name,
a.service_order_supplier_name
