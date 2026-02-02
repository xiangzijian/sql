-- 及时上门测算明细：2025年租后维修单准时上门明细数据
-- 用于核对和分析具体订单的上门情况
-- 更新日期：2026-01-15

WITH 
-- 1. 获取首次修改服务时间的记录（从操作历史表）
first_service_change AS (
    SELECT 
        service_order_code,
        remark,
        operate_time,
        ROW_NUMBER() OVER (PARTITION BY service_order_code ORDER BY operate_time ASC) AS rn
    FROM dw.dw_fas_jiafu_dispatch_service_order_operate_history_da
    WHERE pt = (SELECT MAX(pt) FROM dw.dw_fas_jiafu_dispatch_service_order_operate_history_da)
        AND operate_type_name = '修改服务时间'
),

-- 2. 提取修改后的服务时间（解析JSON）
changed_service_time AS (
    SELECT 
        service_order_code,
        -- 从JSON中提取变更后的服务开始时间
        get_json_object(remark, '$.changedServiceStart') AS changed_service_start,
        -- 从JSON中提取变更后的服务结束时间
        get_json_object(remark, '$.changedServiceEnd') AS changed_service_end,
        operate_time AS first_change_time,
        remark AS change_remark
    FROM first_service_change
    WHERE rn = 1  -- 只取第一次修改记录
)

-- 3. 订单明细及准时上门判断
SELECT 
    a.order_no AS `订单号`,
    a.order_id AS `订单ID`,
    a.city_name AS `城市`,
    SUBSTR(a.order_create_time, 1, 7) AS `月份`,
    a.order_create_time AS `订单创建时间`,
    
    -- 紧急标识
    a.urgent_flag AS `紧急标识代码`,
    CASE 
        WHEN a.urgent_flag = 1 THEN '紧急单'
        WHEN a.urgent_flag = 0 THEN '非紧急单'
        WHEN a.urgent_flag = 2 THEN '紧急转非紧急'
        ELSE '其他'
    END AS `紧急标识`,
    a.performance_mode AS `履约模式`,
    
    -- 服务单信息
    a.service_order_code AS `服务单编码`,
    a.service_order_status_name AS `服务单状态`,
    a.service_order_supplier_name AS `供应商名称`,
    a.service_order_professional_name AS `服务者姓名`,
    
    -- 预约服务时间
    a.service_start_time AS `原预约开始时间`,
    a.service_end_time AS `原预约结束时间`,
    
    -- 修改后的服务时间
    b.changed_service_start AS `修改后开始时间`,
    b.changed_service_end AS `修改后结束时间`,
    b.first_change_time AS `首次修改时间`,
    CASE 
        WHEN b.changed_service_start IS NOT NULL THEN '是'
        ELSE '否'
    END AS `是否修改过服务时间`,
    
    -- 签到时间
    a.first_sign_time AS `首次签到时间`,
    a.first_dispatch_time AS `首次派单时间`,
    a.first_receive_time AS `首次接单时间`,
    
    -- 时间差计算
    ROUND(
        CASE 
            WHEN a.first_sign_time IS NOT NULL AND a.first_sign_time != '1000-01-01 00:00:00'
            THEN (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
                  - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60
            ELSE NULL
        END, 
    2) AS `创建到签到分钟数`,
    
    ROUND(
        CASE 
            WHEN a.first_sign_time IS NOT NULL AND a.first_sign_time != '1000-01-01 00:00:00'
            THEN (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
                  - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 / 60
            ELSE NULL
        END, 
    2) AS `创建到签到小时数`,
    
    -- 紧急单判断（2小时内）
    CASE 
        WHEN a.urgent_flag = 1 THEN
            CASE 
                WHEN a.first_sign_time IS NOT NULL 
                    AND a.first_sign_time != '1000-01-01 00:00:00'
                    AND (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
                         - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 120
                THEN '是'
                WHEN a.first_sign_time IS NULL OR a.first_sign_time = '1000-01-01 00:00:00'
                THEN '未签到'
                ELSE '否'
            END
        ELSE '-'
    END AS `紧急单2小时内上门`,
    
    -- 非紧急单判断（在预约时间范围内）
    CASE 
        WHEN a.urgent_flag IN (0, 2) THEN
            CASE 
                WHEN a.first_sign_time IS NULL OR a.first_sign_time = '1000-01-01 00:00:00'
                THEN '未签到'
                -- 有修改服务时间，判断是否在修改后的时间范围内
                WHEN b.changed_service_start IS NOT NULL 
                    AND b.changed_service_end IS NOT NULL
                THEN 
                    CASE 
                        WHEN a.first_sign_time >= b.changed_service_start
                            AND a.first_sign_time <= b.changed_service_end
                        THEN '是(在修改后时间内)'
                        ELSE '否(不在修改后时间内)'
                    END
                -- 无修改服务时间，判断是否在原预约时间范围内
                WHEN a.service_start_time IS NOT NULL
                    AND a.service_end_time IS NOT NULL
                THEN 
                    CASE 
                        WHEN a.first_sign_time >= a.service_start_time
                            AND a.first_sign_time <= a.service_end_time
                        THEN '是(在原预约时间内)'
                        ELSE '否(不在原预约时间内)'
                    END
                ELSE '无预约时间'
            END
        ELSE '-'
    END AS `非紧急单准时上门`,
    
    -- 综合判断
    CASE 
        WHEN a.urgent_flag = 1 THEN
            CASE 
                WHEN a.first_sign_time IS NOT NULL 
                    AND a.first_sign_time != '1000-01-01 00:00:00'
                    AND (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
                         - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 120
                THEN '准时'
                ELSE '不准时'
            END
        WHEN a.urgent_flag IN (0, 2) THEN
            CASE 
                WHEN a.first_sign_time IS NOT NULL 
                    AND a.first_sign_time != '1000-01-01 00:00:00'
                    AND (
                        (b.changed_service_start IS NOT NULL 
                         AND b.changed_service_end IS NOT NULL
                         AND a.first_sign_time >= b.changed_service_start
                         AND a.first_sign_time <= b.changed_service_end)
                        OR
                        (b.changed_service_start IS NULL
                         AND a.service_start_time IS NOT NULL
                         AND a.service_end_time IS NOT NULL
                         AND a.first_sign_time >= a.service_start_time
                         AND a.first_sign_time <= a.service_end_time)
                    )
                THEN '准时'
                ELSE '不准时'
            END
        ELSE '其他'
    END AS `是否准时上门`,
    
    -- 其他订单信息
    a.order_status AS `订单状态代码`,
    a.resblock_name AS `小区名称`,
    a.contact_user AS `联系人`,
    a.user_evaluation_star AS `用户评价星级`,
    a.order_complete_time AS `订单完单时间`,
    a.service_order_complete_time AS `服务单完工时间`,
    
    -- JSON原始数据（用于核对）
    b.change_remark AS `修改服务时间备注JSON`
    
FROM olap.olap_hj_fas_main_order_service_info_da a
LEFT JOIN changed_service_time b 
    ON a.service_order_code = b.service_order_code
    
WHERE a.pt = (SELECT MAX(pt) FROM olap.olap_hj_fas_main_order_service_info_da)
    AND SUBSTR(a.order_create_time, 1, 4) = '2025'  -- 筛选2025年数据
    AND a.order_type = 16  -- 租后维修单（轻托管维修单）
    AND a.first_sign_time IS NOT NULL
    AND a.first_sign_time != '1000-01-01 00:00:00'
    -- 可根据需要添加城市、月份等筛选条件
    -- AND a.city_name = '深圳市'
    -- AND SUBSTR(a.order_create_time, 1, 7) >= '2025-06'
    
ORDER BY 
    a.order_create_time DESC,
    a.city_name,
    a.order_no;
