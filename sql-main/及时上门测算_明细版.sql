-- 及时上门测算明细版：输出每个订单的详细信息
-- 包含：城市、订单号、紧急单类型、首次签到时间、预约服务时间、第一次修改服务时间等
-- 筛选条件：2025年11月，济南市
-- 紧急单定义：urgent_flag = 1 或 2（包括紧急转非紧急），标准为2小时内上门
-- 非紧急单定义：urgent_flag = 0，标准为预约时间内上门
-- 
-- 剔除条件：
-- 1. 非紧急单：剔除没有致电时间（first_call_time）且order_status=50的取消单
-- 2. 紧急单：剔除夜间（21点到次日9点）取消的订单
-- 3. 紧急单：剔除白天（9点到21点）没有致电时间且order_status=50的取消单
-- 
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
    WHERE pt = '20260114000000'
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
        -- 第一次修改服务时间的时间段（格式化显示）
        CONCAT(
            get_json_object(remark, '$.changedServiceStart'), 
            ' ~ ', 
            get_json_object(remark, '$.changedServiceEnd')
        ) AS first_change_time_range
    FROM first_service_change
    WHERE rn = 1  -- 只取第一次修改记录
),

-- 3. 主订单数据及准时上门判断
main_order_data AS (
    SELECT 
        a.order_no,
        a.order_id,
        a.city_code,
        a.city_name,
        a.order_create_time,
        SUBSTR(a.order_create_time, 1, 7) AS order_month,
        a.service_order_code,
        a.urgent_flag,
        CASE 
            WHEN a.urgent_flag = 1 THEN '紧急'
            WHEN a.urgent_flag = 0 THEN '非紧急'
            WHEN a.urgent_flag = 2 THEN '紧急转非'
            ELSE '其他'
        END AS urgent_type,
        a.first_sign_time,
        a.first_call_time,
        a.cancel_time,
        a.order_status,
        a.service_start_time,
        a.service_end_time,
        
        -- 第一次修改服务时间的操作时间
        b.first_change_time,
        -- 第一次修改后的服务开始时间
        b.changed_service_start,
        -- 第一次修改后的服务结束时间
        b.changed_service_end,
        -- 第一次修改服务时间的时间段
        b.first_change_time_range,
        
        -- 原始预约服务时间段
        CONCAT(
            CASE 
                WHEN a.service_start_time IS NOT NULL AND a.service_start_time != '1000-01-01 00:00:00'
                THEN a.service_start_time
                ELSE '无'
            END,
            ' ~ ',
            CASE 
                WHEN a.service_end_time IS NOT NULL AND a.service_end_time != '1000-01-01 00:00:00'
                THEN a.service_end_time
                ELSE '无'
            END
        ) AS original_service_time_range,
        
        -- 计算订单创建到首次签到的分钟数
        CASE 
            WHEN a.first_sign_time IS NOT NULL AND a.first_sign_time != '1000-01-01 00:00:00'
            THEN (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
                  - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60
            ELSE NULL
        END AS create_to_sign_minutes,
        
        -- 判断紧急单是否2小时内上门（urgent_flag = 1 或 2 都算紧急单）
        CASE 
            WHEN a.urgent_flag IN (1, 2)  -- 紧急单和紧急转非紧急都按紧急单标准
                AND a.first_sign_time IS NOT NULL 
                AND a.first_sign_time != '1000-01-01 00:00:00'
                AND (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
                     - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 120
            THEN '是'
            WHEN a.urgent_flag IN (1, 2)
            THEN '否'
            ELSE NULL
        END AS is_urgent_ontime,
        
        -- 判断非紧急单是否准时上门（只有 urgent_flag = 0）
        CASE 
            WHEN a.urgent_flag = 0  -- 只有非紧急单按预约时间判断
                AND a.first_sign_time IS NOT NULL 
                AND a.first_sign_time != '1000-01-01 00:00:00'
                AND (
                    -- 情况1：有修改服务时间，判断是否在修改后的时间范围内
                    (b.changed_service_start IS NOT NULL 
                     AND b.changed_service_end IS NOT NULL
                     AND a.first_sign_time >= b.changed_service_start
                     AND a.first_sign_time <= b.changed_service_end)
                    OR
                    -- 情况2：无修改服务时间，判断是否在原预约时间范围内
                    (b.changed_service_start IS NULL
                     AND a.service_start_time IS NOT NULL
                     AND a.service_end_time IS NOT NULL
                     AND a.first_sign_time >= a.service_start_time
                     AND a.first_sign_time <= a.service_end_time)
                )
            THEN '是'
            WHEN a.urgent_flag = 0
            THEN '否'
            ELSE NULL
        END AS is_normal_ontime,
        
        -- 综合准时上门判断
        CASE 
            -- 紧急单（包括紧急转非）：2小时内上门
            WHEN a.urgent_flag IN (1, 2)
                AND a.first_sign_time IS NOT NULL 
                AND a.first_sign_time != '1000-01-01 00:00:00'
                AND (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
                     - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 120
            THEN '是'
            -- 非紧急单：预约时间内上门
            WHEN a.urgent_flag = 0
                AND a.first_sign_time IS NOT NULL 
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
            THEN '是'
            ELSE '否'
        END AS is_ontime,
        
        -- 补充字段
        a.service_order_supplier_name,
        a.service_order_professional_name,
        a.service_order_professional_ucid,
        c.commodity_name_list1,
        a.order_complete_time
        
    FROM olap.olap_hj_fas_main_order_service_info_da a
    LEFT JOIN changed_service_time b 
        ON a.service_order_code = b.service_order_code
    INNER JOIN (
        SELECT 
            order_no,
            commodity_name_list1,
            supplier_name
        FROM rpt.rpt_fas_light_hosting_order_detail_da
        WHERE pt = '20260114000000'
            AND vison_type = '4.0'
            AND service_name IN ('维修', '燃气')
            AND order_type = '16'
            AND label_group NOT IN ('8')
            AND commodity_name_list1 != '漏水专项检修'
            AND commodity_name_list1 NOT IN (
                '夏季空调预检', 'SCM00300001672373', '漏水专项检修','消防器材', '定损', '漏水定损','火灾定损','其他定损', '京北漏水定损', '京南漏水定损','京北火灾定损', '京南火灾定损',
                '京北其他定损', '京南其他定损')
            AND supplier_name NOT IN (
                '上海兰宫建筑装饰有限公司',
                '上海尚礼实业有限公司',
                '上海苏皖贸易有限公司',
                '上海再旭保洁服务有限公司',
                '源和里仁家具海安有限公司',
                '匠云（北京）科技有限公司'
            )
    ) c ON c.order_no = a.order_no
    WHERE a.pt = '20260114000000'
        AND SUBSTR(a.order_create_time, 1, 7) = '2025-11'  -- 筛选2025年11月数据
        AND a.city_name = '济南市'  -- 筛选济南市
        AND a.order_type = 16  -- 租后维修单（轻托管维修单）
        AND a.label_group NOT IN ('1', '8', '25')  -- 去掉漏水、定损
        AND a.lease_status IN (2, 3)  -- 租赁状态筛选
        AND a.first_sign_time IS NOT NULL
        AND a.first_sign_time != '1000-01-01 00:00:00'
        
        -- 非紧急单剔除条件：去除没有致电时间且order_status=50的取消单
        AND NOT (
            a.urgent_flag = 0 
            AND a.order_status = 50 
            AND (a.first_call_time IS NULL 
                 OR a.first_call_time = '1000-01-01 00:00:00' 
                 OR SUBSTR(a.first_call_time, 1, 4) < '2000')
        )
        
        -- 紧急单剔除条件1：剔除夜间（21点到第二天9点）取消的订单
        AND NOT (
            a.urgent_flag IN (1, 2)
            AND a.order_status = 50
            AND a.cancel_time IS NOT NULL
            AND a.cancel_time != '1000-01-01 00:00:00'
            AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
            AND (
                CAST(SUBSTR(a.cancel_time, 12, 2) AS INT) >= 21  -- 晚上21点之后
                OR CAST(SUBSTR(a.cancel_time, 12, 2) AS INT) < 9  -- 早上9点之前
            )
        )
        
        -- 紧急单剔除条件2：剔除白天没有致电时间就order_status=50的取消单
        AND NOT (
            a.urgent_flag IN (1, 2)
            AND a.order_status = 50
            AND a.cancel_time IS NOT NULL
            AND a.cancel_time != '1000-01-01 00:00:00'
            AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
            AND CAST(SUBSTR(a.cancel_time, 12, 2) AS INT) >= 9   -- 早上9点之后
            AND CAST(SUBSTR(a.cancel_time, 12, 2) AS INT) < 21   -- 晚上21点之前
            AND (a.first_call_time IS NULL 
                 OR a.first_call_time = '1000-01-01 00:00:00'
                 OR SUBSTR(a.first_call_time, 1, 4) < '2000')
        )
)

-- 4. 输出明细数据
SELECT 
    city_name AS `城市`,
    order_no AS `订单号`,
    urgent_type AS `紧急单类型`,
    order_status AS `订单状态`,
    order_create_time AS `订单创建时间`,
    first_call_time AS `首次呼叫时间`,
    first_sign_time AS `首次签到时间`,
    cancel_time AS `取消时间`,
    service_start_time AS `预约服务开始时间`,
    service_end_time AS `预约服务结束时间`,
    original_service_time_range AS `原始预约服务时间段`,
    
    -- 第一次修改服务时间的相关信息
    first_change_time AS `第一次修改服务时间的操作时间`,
    changed_service_start AS `第一次修改后的服务开始时间`,
    changed_service_end AS `第一次修改后的服务结束时间`,
    first_change_time_range AS `第一次修改服务时间的时间段`,
    
    -- 准时上门判断
    is_ontime AS `是否准时上门`,
    is_urgent_ontime AS `紧急单2小时内上门`,
    is_normal_ontime AS `非紧急单预约时间内上门`,
    
    -- 计算字段
    ROUND(create_to_sign_minutes, 2) AS `创建到签到分钟数`,
    
    -- 补充信息
    service_order_supplier_name AS `供应商`,
    service_order_professional_name AS `服务者姓名`,
    service_order_professional_ucid AS `服务者UCID`,
    commodity_name_list1 AS `商品名称`,
    order_complete_time AS `订单完工时间`,
    order_month AS `月份`
    
FROM main_order_data
ORDER BY city_name, order_create_time DESC;
