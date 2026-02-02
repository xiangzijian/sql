-- 北京检修任务：按检修单提交时间筛选1月份数据，按收房/出房统计
-- 关联维修综合单，统计是否上门（首次签到时间）

WITH 
-- 任务数据：检修单提交时间在1月份，北京市
task_base AS (
    SELECT 
        task_id,
        houseinout_type,     -- 合同类型：收房/出房
        property_code,       -- 检修单编码
        property_submit_time,-- 检修单提交时间
        trusteeship_housedel_code,  -- 托管房源编码
        city_name
    FROM olap.olap_trusteeship_hdel_delivery_examine_task_da
    WHERE pt = '20260131000000'
        AND city_name = '北京市'
        -- 按检修单提交时间筛选1月份
        AND property_submit_time IS NOT NULL
        AND property_submit_time != ''
        AND property_submit_time != '1000-01-01 00:00:00'
        AND SUBSTR(property_submit_time, 1, 7) = '2026-01'
        AND property_code IS NOT NULL
),

-- 筛选收房/出房
task_with_type AS (
    SELECT 
        task_id,
        property_code,
        property_submit_time,
        trusteeship_housedel_code,  -- 托管房源编码
        city_name,
        houseinout_type AS `收房or出房`  -- 直接使用原值
    FROM task_base
    WHERE houseinout_type IN ('收房', '出房')
),

-- 关联检修单归属表，取家服订单编码
task_with_order_code AS (
    SELECT 
        t.task_id,
        t.property_code,
        t.property_submit_time,
        t.trusteeship_housedel_code,  -- 托管房源编码
        t.`收房or出房`,
        t.city_name,
        d.order_code   -- 家服订单编码
    FROM task_with_type t
    LEFT JOIN olap.olap_trusteeship_hdel_examine_divide_da d
        ON t.property_code = d.property_code
        AND t.city_name = d.city_name
        AND d.pt = '20260131000000'
        AND d.order_code IS NOT NULL
),

-- 关联家服订单表（只保留维修综合订单）
task_with_order_raw AS (
    SELECT 
        t.task_id,
        t.property_code,
        t.property_submit_time,
        t.trusteeship_housedel_code,  -- 托管房源编码
        t.`收房or出房`,
        t.city_name,
        t.order_code,
        o.order_no,
        o.professional_tag_category,
        o.first_sign_time
    FROM task_with_order_code t
    LEFT JOIN olap.olap_hj_fas_main_order_service_info_da o
        ON t.order_code = o.order_no
        AND o.pt = '20260131000000'
        AND o.city_name = t.city_name
        -- 只保留维修综合订单
        AND o.professional_tag_category IS NOT NULL
        AND o.professional_tag_category LIKE '%维修综合%'
),

-- 按检修单编码去重，同一个检修单编码只保留一个维修综合单号
task_with_order AS (
    SELECT 
        task_id,
        property_code,
        property_submit_time,
        trusteeship_housedel_code,  -- 托管房源编码
        `收房or出房`,
        city_name,
        order_code,
        order_no,
        professional_tag_category,
        first_sign_time
    FROM (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY property_code  -- 按检修单编码去重
                ORDER BY order_no  -- 按维修单号排序，取第一个
            ) AS rn
        FROM task_with_order_raw
    ) x
    WHERE rn = 1
)

-- 导出明细表（只包含维修综合单）
SELECT 
    t.city_name AS `城市`,
    t.`收房or出房` AS `收房/出房`,
    t.property_code AS `检修单编码`,
    t.trusteeship_housedel_code AS `托管房源编码`,
    t.property_submit_time AS `检修单提交时间`,
    t.order_no AS `对应的维修单号`,
    CASE 
        WHEN t.first_sign_time IS NOT NULL 
            AND t.first_sign_time != ''
            AND t.first_sign_time != '1000-01-01 00:00:00'
            AND SUBSTR(t.first_sign_time, 1, 4) >= '2000'
        THEN '是'
        ELSE '否'
    END AS `是否上门`,
    t.first_sign_time AS `首次签到时间`
FROM task_with_order t
WHERE t.`收房or出房` IN ('收房', '出房')
    AND t.property_code IS NOT NULL
    AND TRIM(t.property_code) != ''
    AND t.order_no IS NOT NULL  -- 确保有维修单号
ORDER BY t.property_submit_time, t.property_code, t.order_no;
