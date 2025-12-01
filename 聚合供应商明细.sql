SELECT 
    -- === 基础维度 ===
    t1.city_name,
    COALESCE(t5.service_order_supplier_name, '待分配') as `供应商`,
    COALESCE(t5.service_order_professional_name, '') as `服务者姓名`,
    t5.service_order_professional_ucid as `服务者ucid`,
    
    -- === 任务信息 (主键) ===
    t1.task_id,
    t1.status as `任务状态码`,
    CASE 
        WHEN t1.status = 2 THEN '待处理'
        WHEN t1.status = 3 THEN '跟进中'
        WHEN t1.status = 4 THEN '已完结'
        ELSE '其他状态'
    END as `任务状态描述`,
    
    -- === 关联单号信息 ===
    t3.replace_order_code as `换新单号`,
    t5.order_no as `服务单号`,
    
    -- === 指标验证：包外数 (baowai) ===
    -- 逻辑：有服务单 且 备注为包外方案申请
    t5.last_suspend_remark,
    CASE 
        WHEN t5.order_no is not null and t5.last_suspend_remark = '包外方案申请' 
        THEN 1 ELSE 0 
    END as `is_baowai`,
    
    -- === 指标验证：包外提交数 (baowai1) ===
    -- 逻辑：有服务单 且 BPM日志有提交记录(type=1)
    t6.has_operate_1,
    CASE 
        WHEN t5.order_no is not null and t6.has_operate_1 = 1 
        THEN 1 ELSE 0 
    END as `is_baowai1`,
    
    -- === 指标验证：包外驳回数 (baowai2) ===
    -- 逻辑：直接取该订单的驳回总次数，后续求和即可
    COALESCE(t6.operate_2_count, 0) as `cnt_baowai2_reject`,
    
    -- === 指标验证：暂时不为修时长 ===
    -- 逻辑：换新单更新时间 - 签到时间
    t5.first_sign_time as `首次签到时间`,
    t3.update_time as `换新单更新时间`,
    t3.no_maintain_reason_desc as `暂不维修原因`,
    CASE
        WHEN t5.first_sign_time is not null and t3.no_maintain_reason_desc is not null
        THEN (
            unix_timestamp(t3.update_time, 'yyyy-MM-dd HH:mm:ss')
            - unix_timestamp(t5.first_sign_time, 'yyyy-MM-dd HH:mm:ss')
        ) / 3600.0
        ELSE NULL
    END as `calc_duration_wait_repair_hours`,
    
    -- === 指标验证：提交包外方案时长 ===
    -- 逻辑：BPM首次提交时间 - 签到时间
    t6.first_create_time as `BPM首次提交时间`,
    CASE
        WHEN t5.first_sign_time is not null and t6.first_create_time is not null 
        THEN (
            unix_timestamp(t6.first_create_time, 'yyyy-MM-dd HH:mm:ss')
            - unix_timestamp(t5.first_sign_time, 'yyyy-MM-dd HH:mm:ss')
        ) / 3600.0
        ELSE NULL
    END as `calc_duration_submit_plan_hours`

FROM (
    SELECT *
    FROM rpt.rpt_plat_manager_workbench_manager_task_da
    WHERE pt = '${-1d_pt}'
      AND task_define_id = '447'
) t1

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
        -- 标记是否有提交 (type=1)
        max(case when operate_type = 1 then 1 else 0 end) as has_operate_1,
        -- 统计驳回总次数 (type=2)
        count(case when operate_type = 2 then 1 end) as operate_2_count,
        -- 取最早提交时间
        min(create_time) as first_create_time
    FROM olap.olap_hj_fas_main_order_service_out_free_repair_plan_bpm_log_da
    WHERE pt = '${-1d_pt}'
    GROUP BY order_no
) t6 ON t3.replace_order_code = t6.order_no