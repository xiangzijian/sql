SELECT 
    -- === 基础维度 ===
    t1.city_name,
    t1.manager_user_comp_code,
    
    -- === 任务信息 (主键) ===
    t1.task_id,
    t1.status as `任务状态码`,
    CASE 
        WHEN t1.status = 2 THEN '待处理'
        WHEN t1.status = 3 THEN '跟进中'
        WHEN t1.status = 4 THEN '已完结'
        ELSE '其他状态'
    END as `任务状态描述`,
    
    -- === 关联信息 ===
    t1.downstream_code as `物业交割code`,
    t3.replace_order_code as `换新单号`,
    t5.order_no as `服务单号`,
    
    -- === 指标验证：同意客户诉求 (JSON提取) ===
    -- 提取出的原始值，用于检查是否提取正确（应为"是"或"否"或NULL）
    regexp_extract(t2.item_data, '"code":"sftykhsq"[^}]*?"value":"([^"]*?)"', 1) as `extract_sftykhsq`,
    
    -- 聚合统计用的 0/1 标识
    CASE 
        WHEN t2.item_data is not null 
             and regexp_extract(t2.item_data, '"code":"sftykhsq"[^}]*?"value":"([^"]*?)"', 1) = '是' 
        THEN 1 ELSE 0 
    END as `is_agree_customer`,
    
    -- === 指标验证：平均完成时间 (完工 - 建单) ===
    t5.order_create_time as `服务单建单时间`,
    t5.service_order_complete_time as `服务单完工时间`,
    CASE
        WHEN t5.service_order_complete_time is not null
          and t5.order_create_time is not null
        THEN (
            unix_timestamp(t5.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
            - unix_timestamp(t5.order_create_time, 'yyyy-MM-dd HH:mm:ss')
        ) / 3600.0
        ELSE NULL
    END as `calc_duration_finish_hours`,
    
    -- === 指标验证：平均包外时效 (BPM首次提交 - 完工) ===
    t6.first_create_time as `BPM首次提交时间`,
    CASE
        WHEN t5.service_order_complete_time is not null
          and t6.first_create_time is not null
        THEN (
            unix_timestamp(t6.first_create_time, 'yyyy-MM-dd HH:mm:ss')
            - unix_timestamp(t5.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
        ) / 3600.0
        ELSE NULL
    END as `calc_duration_baowai_hours`

FROM (
    SELECT *
    FROM rpt.rpt_plat_manager_workbench_manager_task_da
    WHERE pt = '${-1d_pt}'
      AND task_define_id = '447'
) t1

-- 关联 t2 (已去重，只取换新跟进)
LEFT JOIN (
    select property_code, max(item_data) as item_data
    from dw_plat_lease_property_property_delivery_detail_da
    where pt = '${-1d_pt}'  
      and item_data like '%huanxingenjin%'  
    group by property_code
) t2 ON t1.downstream_code = t2.property_code

LEFT JOIN ods.ods_plat_beijia_transaction_trade_order_replace_info_da t3 
    ON t1.task_id = t3.task_id

LEFT JOIN ( 
    SELECT * 
    FROM olap.olap_hj_fas_main_order_service_info_da 
    WHERE pt = '${-1d_pt}' 
) t5 ON t3.replace_order_code = t5.order_no

LEFT JOIN (
    SELECT 
        order_no,
        min(create_time) as first_create_time
    FROM olap.olap_hj_fas_main_order_service_out_free_repair_plan_bpm_log_da
    WHERE pt = '${-1d_pt}'
    GROUP BY order_no
) t6 ON t3.replace_order_code = t6.order_no