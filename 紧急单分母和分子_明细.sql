-- 紧急单明细：2025年6月-12月各订单明细数据（用于核对旧口径和新口径）
SELECT 
    t1.order_no AS `订单号`,
    t1.order_create_time AS `订单创建时间`,
    SUBSTR(t1.order_create_time, 1, 7) AS `月份`,
    CASE 
        WHEN t1.city_name = '北京市' THEN t1.manager_corp_name 
        ELSE t1.city_name  
    END AS `城市`,
    
    -- 基础字段
    t1.is_urgent_order AS `是否紧急单(is_urgent_order)`,
    t1.is_urgent_switch AS `紧急开关(is_urgent_switch)`,
    t1.is_2_hour_urgent_on_door AS `是否2小时上门`,
    t1.urgent_flag AS `紧急标识(urgent_flag)`,
    t1.performance_mode AS `履约模式(performance_mode)`,
    
    -- 取消状态和时间
    t2.order_status AS `订单状态`,
    CASE 
        WHEN t2.order_status = 50 THEN '已取消'
        WHEN t2.order_status IS NOT NULL THEN CAST(t2.order_status AS STRING)
        ELSE '未知'
    END AS `订单状态说明`,
    t2.cancel_time AS `取消时间`,
    HOUR(t2.cancel_time) AS `取消时间_小时`,
    
    -- 夜间取消判断
    CASE 
        WHEN t2.cancel_time IS NOT NULL 
            AND (HOUR(t2.cancel_time) >= 21 OR HOUR(t2.cancel_time) < 9)
        THEN '是'
        WHEN t2.cancel_time IS NOT NULL 
        THEN '否'
        ELSE '未取消'
    END AS `是否夜间取消(21点-9点)`,
    
    -- 新口径需排除的订单判断
    CASE 
        WHEN t2.order_status = 50 
            AND t2.cancel_time IS NOT NULL 
            AND (HOUR(t2.cancel_time) >= 21 OR HOUR(t2.cancel_time) < 9)
        THEN '是'
        ELSE '否'
    END AS `是否夜间取消单(status=50且21点-9点)`,
    
    -- ========== 旧口径判断 ==========
    CASE 
        WHEN t1.is_urgent_order = 1 OR t1.is_urgent_switch = 1 
        THEN '是'
        ELSE '否'
    END AS `旧口径_计入分母`,
    
    CASE 
        WHEN t1.is_2_hour_urgent_on_door = 1 
            AND (t1.is_urgent_order = 1 OR t1.is_urgent_switch = 1)
        THEN '是'
        ELSE '否'
    END AS `旧口径_计入分子`,
    
    -- ========== 新口径判断（剔除order_status=50且夜间取消的订单） ==========
    CASE 
        WHEN (t1.is_urgent_order = 1 OR t1.is_urgent_switch = 1)
            AND NOT (
                -- 排除：订单状态为50（取消）且取消时间在夜间（21点-9点）
                t2.order_status = 50
                AND t2.cancel_time IS NOT NULL 
                AND (HOUR(t2.cancel_time) >= 21 OR HOUR(t2.cancel_time) < 9)
            )
        THEN '是'
        ELSE '否'
    END AS `新口径_总订单`,
    
    CASE 
        WHEN t1.is_2_hour_urgent_on_door = 1 
            AND (t1.is_urgent_order = 1 OR t1.is_urgent_switch = 1)
            AND NOT (
                -- 排除：订单状态为50（取消）且取消时间在夜间（21点-9点）
                t2.order_status = 50
                AND t2.cancel_time IS NOT NULL 
                AND (HOUR(t2.cancel_time) >= 21 OR HOUR(t2.cancel_time) < 9)
            )
        THEN '是'
        ELSE '否'
    END AS `新口径_2h上门`,
    
    -- 差异标识
    CASE 
        WHEN (
            -- 旧口径计入，但新口径不计入（被排除的夜间取消单）
            (t1.is_urgent_order = 1 OR t1.is_urgent_switch = 1)
            AND t2.order_status = 50
            AND t2.cancel_time IS NOT NULL 
            AND (HOUR(t2.cancel_time) >= 21 OR HOUR(t2.cancel_time) < 9)
        )
        THEN '新旧口径差异(status=50且夜间取消)'
        ELSE ''
    END AS `口径差异说明`
    
FROM rpt.rpt_jiafu_urgent_order_info_da t1
-- 关联订单表获取取消时间
LEFT JOIN olap.olap_hj_fas_main_order_service_info_da t2
    ON t1.order_no = t2.order_no
    AND t2.pt = '20260111000000'

WHERE t1.pt = '20260111000000'
    AND SUBSTR(t1.order_create_time, 1, 7) >= '2025-06'  -- 筛选2025年6月及之后的数据
    AND SUBSTR(t1.order_create_time, 1, 7) <= '2025-12'  -- 筛选2025年12月及之前的数据
    AND (t1.urgent_flag IN (1, 2) OR t1.performance_mode IN (1, 2))
    -- 只保留紧急单相关订单
    AND (t1.is_urgent_order = 1 OR t1.is_urgent_switch = 1)

ORDER BY 
    t1.order_create_time DESC,
    t1.city_name,
    t1.order_no
