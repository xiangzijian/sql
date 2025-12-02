select t1.city_name,
    COALESCE(t5.service_order_supplier_name, '待分配') as `供应商`,
    COALESCE(t5.service_order_professional_name, '') as `服务者姓名`,
    t5.service_order_professional_ucid as `服务者ucid`,
    count(DISTINCT t1.task_id) as task_num,
    count(
        DISTINCT case
            when t1.status = 2 then t1.task_id
        end
    ) as `待处理`,
    count(
        DISTINCT case
            when t1.status = 3 then t1.task_id
        end
    ) as `跟进中`,
    count(
        DISTINCT case
            when t1.status = 4 then t1.task_id
        end
    ) as `已完结`,
    count(
        DISTINCT case
            when t5.order_no is not null
            and t5.last_suspend_remark = '包外方案申请' then t5.order_no
        end
    ) as `baowai`,
    count(
        DISTINCT case
            when t6.has_operate_1 =1 
            then t5.order_no
        end
    ) as `baowai1`,
    sum(
        t6.type2Num
    ) as `baowai2`,
    avg(
        case
            when t5.first_sign_time is not null
            and t3.no_maintain_reason_desc is not null then (
                unix_timestamp(t3.update_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(t5.first_sign_time, 'yyyy-MM-dd HH:mm:ss')
            ) / 3600.0
        end
    ) as `暂时不为修平均时间(小时)`,
    avg(
        case
            when t5.first_sign_time is not null
            and t6.first_create_time is not null then (
                unix_timestamp(t6.first_create_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(t5.first_sign_time, 'yyyy-MM-dd HH:mm:ss')
            ) / 3600.0
        end
    ) as `提交包外方案平均时间(小时)`
from (
        select *
        from rpt.rpt_plat_manager_workbench_manager_task_da
        where pt = '${-1d_pt}'
            and task_define_id = '447'
    ) t1
    left join (
        select *
        from ods.ods_plat_beijia_transaction_trade_order_replace_info_da
    ) t3 on t1.task_id = t3.task_id
    left join (
        SELECT *
        FROM olap.olap_hj_fas_main_order_service_info_da
        WHERE pt = '${-1d_pt}'
    ) t5 on t3.original_order_code = t5.order_no
    LEFT JOIN (
        select order_no,
            min(
                case
                    when node_type = 1 then `update_time`
                end
            ) as `first_create_time`,
           max( case when operate_type = 1 then 1 ELSE 0 end ) as `has_operate_1`,
            count(
                DISTINCT case
                    when operate_type = 2 then `update_time`
                end
            ) as `type2Num`
        from olap.olap_hj_fas_main_order_service_out_free_repair_plan_bpm_log_da
        where pt = '20251130000000'
        GROUP by order_no
    ) t6 ON t3.original_order_code = t6.order_no
GROUP BY t1.city_name,
    COALESCE(t5.service_order_supplier_name, '待分配'),
    COALESCE(t5.service_order_professional_name, ''),
    t5.service_order_professional_ucid