-- 租期维修单及时完工统计：2025年6-12月按城市按月
-- 及时完工定义：完工时间 - 开始时间 <= 24小时
-- 开始时间判断：首次签到时间<=预约服务开始时间则用签到时间，否则用预约服务开始时间
WITH 
-- 1. 主订单数据及及时完工判断
main_order_data AS (
    SELECT 
        a.order_no,
        a.order_id,
        a.city_code,
        a.city_name,
        a.bizcircle_name,
        a.order_create_time,
        SUBSTR(a.order_create_time, 1, 7) AS order_month,
        a.service_order_code,
        a.first_sign_time,
        a.service_start_time,
        a.service_end_time,
        a.service_order_complete_time,
        a.order_status,
        c.commodity_name_list1,
        c.supplier_name,
        
        -- 判断开始时间：签到时间<=预约服务开始时间用签到，否则用预约服务开始时间
        CASE 
            WHEN a.first_sign_time IS NOT NULL 
                AND a.first_sign_time != '1000-01-01 00:00:00'
                AND a.service_start_time IS NOT NULL
                AND a.service_start_time != '1000-01-01 00:00:00'
                AND a.first_sign_time <= a.service_start_time
            THEN a.first_sign_time  -- 签到时间<=预约时间，用签到时间
            WHEN a.service_start_time IS NOT NULL
                AND a.service_start_time != '1000-01-01 00:00:00'
            THEN a.service_start_time  -- 签到时间>预约时间或无签到时间，用预约服务开始时间
            ELSE NULL
        END AS start_time,
        
        -- 计算完工时长（小时）
        CASE 
            WHEN a.service_order_complete_time IS NOT NULL 
                AND a.service_order_complete_time != '1000-01-01 00:00:00'
                AND (
                    -- 有签到且签到<=预约时间
                    (a.first_sign_time IS NOT NULL 
                     AND a.first_sign_time != '1000-01-01 00:00:00'
                     AND a.service_start_time IS NOT NULL
                     AND a.service_start_time != '1000-01-01 00:00:00'
                     AND a.first_sign_time <= a.service_start_time)
                    OR
                    -- 或者有预约时间
                    (a.service_start_time IS NOT NULL
                     AND a.service_start_time != '1000-01-01 00:00:00')
                )
            THEN 
                (UNIX_TIMESTAMP(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - 
                 UNIX_TIMESTAMP(
                    CASE 
                        WHEN a.first_sign_time IS NOT NULL 
                            AND a.first_sign_time != '1000-01-01 00:00:00'
                            AND a.service_start_time IS NOT NULL
                            AND a.service_start_time != '1000-01-01 00:00:00'
                            AND a.first_sign_time <= a.service_start_time
                        THEN a.first_sign_time
                        ELSE a.service_start_time
                    END, 
                    'yyyy-MM-dd HH:mm:ss'
                )) / 3600.0
            ELSE NULL
        END AS finish_hours,
        
        -- 判断是否及时完工（24小时内）
        CASE 
            WHEN a.service_order_complete_time IS NOT NULL 
                AND a.service_order_complete_time != '1000-01-01 00:00:00'
                AND (
                    (a.first_sign_time IS NOT NULL 
                     AND a.first_sign_time != '1000-01-01 00:00:00'
                     AND a.service_start_time IS NOT NULL
                     AND a.service_start_time != '1000-01-01 00:00:00'
                     AND a.first_sign_time <= a.service_start_time)
                    OR
                    (a.service_start_time IS NOT NULL
                     AND a.service_start_time != '1000-01-01 00:00:00')
                )
                AND (UNIX_TIMESTAMP(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - 
                     UNIX_TIMESTAMP(
                        CASE 
                            WHEN a.first_sign_time IS NOT NULL 
                                AND a.first_sign_time != '1000-01-01 00:00:00'
                                AND a.service_start_time IS NOT NULL
                                AND a.service_start_time != '1000-01-01 00:00:00'
                                AND a.first_sign_time <= a.service_start_time
                            THEN a.first_sign_time
                            ELSE a.service_start_time
                        END, 
                        'yyyy-MM-dd HH:mm:ss'
                    )) / 3600.0 <= 24
            THEN 1
            ELSE 0
        END AS is_ontime_finish
        
    FROM olap.olap_hj_fas_main_order_service_info_da a
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
                '夏季空调预检', 'SCM00300001672373', '漏水专项检修','消防器材', '定损', '漏水定损','火灾定损','其他定损', 
                '京北漏水定损', '京南漏水定损','京北火灾定损', '京南火灾定损',
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
        AND SUBSTR(a.order_create_time, 1, 4) = '2025'  -- 2025年
        AND SUBSTR(a.order_create_time, 6, 2) BETWEEN '06' AND '12'  -- 6月到12月
        AND a.order_type = 16  -- 租后维修单（轻托管维修单）
        AND a.label_group NOT IN ('1', '8', '25')  -- 去掉漏水、定损
        AND a.lease_status IN (2, 3)  -- 租赁状态筛选
)

-- 2. 最终统计结果
SELECT 
    city_name AS `城市`,
    bizcircle_name AS `商圈`,
    order_month AS `月份`,
    
    -- 总订单数
    COUNT(DISTINCT order_no) AS `租期订单量`,
    
    -- 及时完工统计
    COUNT(DISTINCT CASE WHEN is_ontime_finish = 1 THEN order_no END) AS `24小时内完工数`,
    CONCAT(
        ROUND(
            CASE 
                WHEN COUNT(DISTINCT order_no) = 0 THEN 0
                ELSE COUNT(DISTINCT CASE WHEN is_ontime_finish = 1 THEN order_no END) * 100.0 
                     / COUNT(DISTINCT order_no)
            END, 
        2), '%'
    ) AS `24小时完工率`,
    
    -- 平均完工时长
    ROUND(AVG(finish_hours), 2) AS `平均完工时长(小时)`,
    
    -- 中位数完工时长（近似）
    ROUND(
        PERCENTILE(CAST(finish_hours AS BIGINT), 0.5), 
    2) AS `中位数完工时长(小时)`,
    
    -- 完工时长分布
    COUNT(DISTINCT CASE WHEN finish_hours <= 24 THEN order_no END) AS `24小时内`,
    COUNT(DISTINCT CASE WHEN finish_hours > 24 AND finish_hours <= 48 THEN order_no END) AS `24-48小时`,
    COUNT(DISTINCT CASE WHEN finish_hours > 48 AND finish_hours <= 72 THEN order_no END) AS `48-72小时`,
    COUNT(DISTINCT CASE WHEN finish_hours > 72 THEN order_no END) AS `72小时以上`
    
FROM main_order_data
GROUP BY city_name, bizcircle_name, order_month
ORDER BY city_name, bizcircle_name, order_month
