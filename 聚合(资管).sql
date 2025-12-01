select t1.city_name,
       t1.manager_user_comp_code,
       count(DISTINCT t1.task_id) as task_num,
       count(DISTINCT case when t1.status =2 then t1.task_id end) as `待处理`,
       count(DISTINCT case when t1.status =3 then t1.task_id end) as `跟进中`,
       count(DISTINCT case when t1.status =4 then t1.task_id end) as `已完结`,
      count(DISTINCT case 
            when t2.item_data is not null and regexp_extract(t2.item_data, '"code":"sftykhsq"[^}]*?"value":"([^"]*?)"', 1) = '是' 
            then t1.task_id 
       end) as `同意客户诉求_是`,
       avg(
           case
               when t5.service_order_complete_time is not null
                 and t5.order_create_time is not null
               then (
                   unix_timestamp(t5.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
                   - unix_timestamp(t5.order_create_time, 'yyyy-MM-dd HH:mm:ss')
               ) / 3600.0
           end
       ) as `平均完成时间(小时)`,
        avg(
           case
               when t5.service_order_complete_time is not null
                 and t6.first_create_time is not null
               then (
                   unix_timestamp(t5.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
                   - unix_timestamp(t6.first_create_time, 'yyyy-MM-dd HH:mm:ss')
               ) / 3600.0
           end
       ) as `平均包外时效时间(小时)`
from (
        select *
        from rpt_plat_manager_workbench_manager_task_da
        where pt = '${-1d_pt}'
            and task_define_id = '447'
    ) t1
    left join (
        select property_code,max(item_data) item_data
        from dw.dw_plat_lease_property_property_delivery_detail_da
        where pt = '${-1d_pt}'  and item_data like '%huanxingenjin%'  group by property_code
    ) t2 on t1.downstream_code = t2.property_code
    left join (
        select *
        from ods.ods_plat_beijia_transaction_trade_order_replace_info_da
    ) t3 on t1.task_id = t3.task_id
    left join ( SELECT * FROM olap_hj_fas_main_order_service_info_da WHERE pt = '${-1d_pt}' ) t5
    on t3.original_order_code = t5.order_no
    LEFT JOIN (
        select order_no,min( case when node_type =1 then `update_time` end ) as `first_create_time`
        from olap.olap_hj_fas_main_order_service_out_free_repair_plan_bpm_log_da
        where pt = '20251130000000' GROUP by order_no
    ) t6 ON t3.original_order_code = t6.order_no

    GROUP BY t1.city_name,t1.manager_user_comp_code
 