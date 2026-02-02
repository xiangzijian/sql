-- 及时上门测算明细：济南市2025年11月
-- 用于核对准时上门判断逻辑
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
        operate_time AS first_change_time
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
            WHEN a.urgent_flag = 1 THEN '紧急单'
            WHEN a.urgent_flag = 0 THEN '非紧急单'
            WHEN a.urgent_flag = 2 THEN '紧急转非紧急'
            ELSE '其他'
        END AS urgent_flag_name,
        a.first_sign_time,
        a.first_call_time,
        a.cancel_time,
        a.order_status,
        a.service_start_time,
        a.service_end_time,
        b.changed_service_start,
        b.changed_service_end,
        c.commodity_name_list1,
        c.supplier_name,
        
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
            THEN 1
            ELSE 0
        END AS is_urgent_ontime,
        
        -- 判断非紧急单是否准时上门（只有 urgent_flag = 0）
        CASE 
            WHEN a.urgent_flag = 0  -- 只有非紧急单按预约时间判断
                AND a.first_sign_time IS NOT NULL 
                AND a.first_sign_time != '1000-01-01 00:00:00'
                AND (
                    -- 情况1：有致电时间，判断首次签到时间是否小于等于预约服务开始时间
                    (a.first_call_time IS NOT NULL 
                     AND a.first_call_time != '1000-01-01 00:00:00'
                     AND SUBSTR(a.first_call_time, 1, 4) >= '2000'
                     AND a.service_start_time IS NOT NULL
                     AND a.first_sign_time <= a.service_start_time)
                    OR
                    -- 情况2：没有致电时间，判断首次签到时间是否小于等于修改后的服务开始时间
                    ((a.first_call_time IS NULL 
                      OR a.first_call_time = '1000-01-01 00:00:00'
                      OR SUBSTR(a.first_call_time, 1, 4) < '2000')
                     AND b.changed_service_start IS NOT NULL
                     AND a.first_sign_time <= b.changed_service_start)
                )
            THEN 1
            ELSE 0
        END AS is_normal_ontime,
        
        -- 判断使用哪种判断逻辑
        CASE 
            WHEN a.urgent_flag IN (1, 2) THEN '紧急单-2小时内上门'
            WHEN a.urgent_flag = 0 
                AND a.first_call_time IS NOT NULL 
                AND a.first_call_time != '1000-01-01 00:00:00'
                AND SUBSTR(a.first_call_time, 1, 4) >= '2000'
            THEN '普通单-有致电-比较原始预约时间'
            WHEN a.urgent_flag = 0
                AND (a.first_call_time IS NULL 
                     OR a.first_call_time = '1000-01-01 00:00:00'
                     OR SUBSTR(a.first_call_time, 1, 4) < '2000')
            THEN '普通单-无致电-比较修改后时间'
            ELSE ''
        END AS ontime_logic_type
        
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
        AND a.city_name = '济南市'  -- 只查济南市
        AND SUBSTR(a.order_create_time, 1, 7) = '2025-11'  -- 只查2025年11月
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
    order_no AS `订单号`,
    city_name AS `城市`,
    order_month AS `月份`,
    urgent_flag_name AS `紧急标识`,
    order_create_time AS `订单创建时间`,
    first_call_time AS `首次致电时间`,
    service_start_time AS `原预约开始时间`,
    service_end_time AS `原预约结束时间`,
    changed_service_start AS `修改后开始时间`,
    changed_service_end AS `修改后结束时间`,
    first_sign_time AS `首次签到时间`,
    order_status AS `订单状态`,
    cancel_time AS `取消时间`,
    commodity_name_list1 AS `商品名称`,
    supplier_name AS `供应商`,
    
    -- 判断逻辑类型
    ontime_logic_type AS `判断逻辑类型`,
    
    -- 紧急单相关（包括紧急单和紧急转非紧急）
    ROUND(create_to_sign_minutes, 2) AS `创建到签到分钟数`,
    CASE 
        WHEN urgent_flag IN (1, 2) THEN 
            CASE WHEN is_urgent_ontime = 1 THEN '是' ELSE '否' END
        ELSE '' 
    END AS `紧急单2小时内上门`,
    
    -- 非紧急单相关（只有非紧急单显示）
    CASE 
        WHEN urgent_flag = 0 THEN 
            CASE WHEN is_normal_ontime = 1 THEN '是' ELSE '否' END
        ELSE '' 
    END AS `非紧急单准时上门`,
    
    -- 综合准时判断
    CASE 
        WHEN (urgent_flag IN (1, 2) AND is_urgent_ontime = 1)
             OR (urgent_flag = 0 AND is_normal_ontime = 1)
        THEN '是'
        ELSE '否'
    END AS `是否准时上门`
    
FROM main_order_data
ORDER BY order_create_time, urgent_flag_name, order_no
