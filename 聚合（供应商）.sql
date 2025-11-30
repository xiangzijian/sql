select t1.city_name,
       t1.service_order_supplier_name as `供应商`,
       t1.service_order_professional_name as `服务者姓名`,
       t1.service_order_professional_ucid as `服务者ucid`,
       count(DISTINCT t1.task_id) as task_num,
       count(DISTINCT case when t1.status =2 then t1.task_id end) as `待处理`,
       count(DISTINCT case when t1.status =3 then t1.task_id end) as `跟进中`,
       count(DISTINCT case when t1.status =4 then t1.task_id end) as `已完结`,
       count(DISTINCT case when t2.item_data is not null then t2.item_data end) as `小区数`,
       avg(
           case
               when t5.service_order_complete_time is not null
                 and t5.order_create_time is not null
               then (
                   unix_timestamp(t5.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
                   - unix_timestamp(t5.order_create_time, 'yyyy-MM-dd HH:mm:ss')
               ) / 3600.0
           end
       ) as `平均完成时间(小时)`
from (
        select *
        from rpt_plat_manager_workbench_manager_task_da
        where pt = '${-1d_pt}'
            and task_define_id = '447'
    ) t1
    left join (
        select *
        from dw_plat_lease_property_property_delivery_detail_da
        where pt = '${-1d_pt}'
    ) t2 on t1.downstream_code = t2.property_code
    left join (
        select *
        from ods.ods_plat_beijia_transaction_trade_order_replace_info_da
    ) t3 on t1.task_id = t3.task_id
    left join ( SELECT * FROM olap_hj_fas_main_order_service_info_da WHERE pt = '${-1d_pt}' ) t5
    on t3.replace_order_code = t5.order_no

    GROUP BY t1.city_name,t1.service_order_supplier_name,t1.service_order_professional_name,t1.service_order_professional_ucid
 