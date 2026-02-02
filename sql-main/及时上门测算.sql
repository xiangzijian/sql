-- 及时上门测算：统计2025年每个城市每月租后维修单准时上门情况
-- 统计范围：2025年全年，按城市、月份、紧急标识分组
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
        a.service_start_time,
        a.service_end_time,
        b.changed_service_start,
        b.changed_service_end,
        
        -- 计算订单创建到首次签到的分钟数
        CASE 
            WHEN a.first_sign_time IS NOT NULL AND a.first_sign_time != '1000-01-01 00:00:00'
            THEN (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
                  - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60
            ELSE NULL
        END AS create_to_sign_minutes,
        
        -- 判断紧急单是否2小时内上门
        CASE 
            WHEN a.urgent_flag = 1 
                AND a.first_sign_time IS NOT NULL 
                AND a.first_sign_time != '1000-01-01 00:00:00'
                AND (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
                     - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 120
            THEN 1
            ELSE 0
        END AS is_urgent_ontime,
        
        -- 判断非紧急单是否准时上门
        CASE 
            WHEN a.urgent_flag IN (0, 2)  -- 非紧急单或紧急转非紧急
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
            THEN 1
            ELSE 0
        END AS is_normal_ontime
        
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
        AND SUBSTR(a.order_create_time, 1, 4) = '2025'  -- 筛选2025年数据
        AND a.order_type = 16  -- 租后维修单（轻托管维修单）
        AND a.label_group NOT IN ('1', '8', '25')  -- 去掉漏水、定损
        AND a.lease_status IN (2, 3)  -- 租赁状态筛选
        AND a.first_sign_time IS NOT NULL
        AND a.first_sign_time != '1000-01-01 00:00:00'
)

-- 4. 最终统计结果
SELECT 
    city_name AS `城市`,
    order_month AS `月份`,
    urgent_flag_name AS `紧急标识`,
    
    -- 总订单数
    COUNT(DISTINCT order_no) AS `总订单数`,
    
    -- 紧急单统计
    COUNT(DISTINCT CASE WHEN urgent_flag = 1 THEN order_no END) AS `紧急单总数`,
    COUNT(DISTINCT CASE WHEN urgent_flag = 1 AND is_urgent_ontime = 1 THEN order_no END) AS `紧急单2小时上门数`,
    CONCAT(
        ROUND(
            CASE 
                WHEN COUNT(DISTINCT CASE WHEN urgent_flag = 1 THEN order_no END) = 0 THEN 0
                ELSE COUNT(DISTINCT CASE WHEN urgent_flag = 1 AND is_urgent_ontime = 1 THEN order_no END) * 100.0 
                     / COUNT(DISTINCT CASE WHEN urgent_flag = 1 THEN order_no END)
            END, 
        2), '%'
    ) AS `紧急单2小时上门率`,
    
    -- 非紧急单统计
    COUNT(DISTINCT CASE WHEN urgent_flag IN (0, 2) THEN order_no END) AS `非紧急单总数`,
    COUNT(DISTINCT CASE WHEN urgent_flag IN (0, 2) AND is_normal_ontime = 1 THEN order_no END) AS `非紧急单准时上门数`,
    CONCAT(
        ROUND(
            CASE 
                WHEN COUNT(DISTINCT CASE WHEN urgent_flag IN (0, 2) THEN order_no END) = 0 THEN 0
                ELSE COUNT(DISTINCT CASE WHEN urgent_flag IN (0, 2) AND is_normal_ontime = 1 THEN order_no END) * 100.0 
                     / COUNT(DISTINCT CASE WHEN urgent_flag IN (0, 2) THEN order_no END)
            END, 
        2), '%'
    ) AS `非紧急单准时上门率`,
    
    -- 综合统计
    COUNT(DISTINCT CASE 
        WHEN (urgent_flag = 1 AND is_urgent_ontime = 1) 
             OR (urgent_flag IN (0, 2) AND is_normal_ontime = 1) 
        THEN order_no 
    END) AS `准时上门总数`,
    CONCAT(
        ROUND(
            CASE 
                WHEN COUNT(DISTINCT order_no) = 0 THEN 0
                ELSE COUNT(DISTINCT CASE 
                    WHEN (urgent_flag = 1 AND is_urgent_ontime = 1) 
                         OR (urgent_flag IN (0, 2) AND is_normal_ontime = 1) 
                    THEN order_no 
                END) * 100.0 / COUNT(DISTINCT order_no)
            END, 
        2), '%'
    ) AS `综合准时上门率`
    
FROM main_order_data
GROUP BY city_name, order_month, urgent_flag_name
ORDER BY city_name, order_month, urgent_flag_name;
