-- 租期维修单及时完工明细：2025年6-12月
-- 用于核对及时完工判断逻辑
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
        
        -- 判断使用哪种开始时间
        CASE 
            WHEN a.first_sign_time IS NOT NULL 
                AND a.first_sign_time != '1000-01-01 00:00:00'
                AND a.service_start_time IS NOT NULL
                AND a.service_start_time != '1000-01-01 00:00:00'
                AND a.first_sign_time <= a.service_start_time
            THEN '使用签到时间'
            WHEN a.service_start_time IS NOT NULL
                AND a.service_start_time != '1000-01-01 00:00:00'
            THEN '使用预约服务开始时间'
            ELSE '无有效开始时间'
        END AS start_time_type,
        
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
        AND a.city_name = '上海市'  -- 限定上海市
        AND SUBSTR(a.order_create_time, 1, 7) = '2025-11'  -- 限定2025年11月
        AND a.order_type = 16  -- 租后维修单（轻托管维修单）
        AND a.label_group NOT IN ('1', '8', '25')  -- 去掉漏水、定损
        AND a.lease_status IN (2, 3)  -- 租赁状态筛选
)

-- 2. 输出明细数据
SELECT 
    order_no AS `订单号`,
    city_name AS `城市`,
    bizcircle_name AS `商圈`,
    order_month AS `月份`,
    order_create_time AS `订单创建时间`,
    first_sign_time AS `首次签到时间`,
    service_start_time AS `预约服务开始时间`,
    service_end_time AS `预约服务结束时间`,
    service_order_complete_time AS `完工时间`,
    
    -- 计算逻辑
    start_time AS `实际开始时间`,
    start_time_type AS `开始时间类型`,
    ROUND(finish_hours, 2) AS `完工时长(小时)`,
    CASE WHEN is_ontime_finish = 1 THEN '是' ELSE '否' END AS `24小时内完工`,
    
    -- 完工时长分段
    CASE 
        WHEN finish_hours <= 24 THEN '24小时内'
        WHEN finish_hours <= 48 THEN '24-48小时'
        WHEN finish_hours <= 72 THEN '48-72小时'
        ELSE '72小时以上'
    END AS `完工时长分段`,
    
    -- 其他信息
    order_status AS `订单状态`,
    commodity_name_list1 AS `商品名称`,
    supplier_name AS `供应商`
    
FROM main_order_data
ORDER BY city_name, bizcircle_name, order_month, order_create_time, order_no
