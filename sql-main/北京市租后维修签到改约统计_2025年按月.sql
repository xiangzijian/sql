-- 北京市2026年1月12日-15日租后维修单签到和改约统计（按日期）
-- 统计签到单量、签到时间与修改后服务时间关系、改约时间差、改约次数
-- 更新日期：2026-01-16

WITH
-- 1. 获取北京市2026年1月12日-15日租后维修单的基础信息
base_orders AS (
    SELECT DISTINCT
        a.service_order_code,
        a.order_no,
        a.city_name,
        a.first_sign_time,  -- 首次签到时间
        a.service_start_time,  -- 预约服务开始时间
        a.modified_service_start_time,  -- 修改后的服务开始时间（最后一次修改）
        a.order_create_time,
        SUBSTR(a.order_create_time, 1, 10) AS order_date  -- 订单日期
    FROM olap.olap_hj_fas_main_order_service_info_da a
    INNER JOIN (
        -- 关联轻托管明细表，排除漏水和定损
        SELECT
            order_no AS oth_orderno
        FROM rpt.rpt_fas_light_hosting_order_detail_da
        WHERE pt = '${-1d_pt}'
            AND vison_type = '4.0'
            AND service_name IN ('维修','燃气')
            AND order_type = '16'
            AND label_group NOT IN ('8')  -- 排除检修
            AND commodity_name_list1 != '漏水专项检修'
            AND commodity_name_list1 NOT IN ('夏季空调预检','SCM00300001672373','漏水专项检修','消防器材','定损','漏水定损','火灾定损','其他定损','京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')
            AND supplier_name NOT IN ('上海兰宫建筑装饰有限公司','上海尚礼实业有限公司','上海苏皖贸易有限公司','上海再旭保洁服务有限公司','源和里仁家具海安有限公司','匠云（北京）科技有限公司')
    ) b ON a.order_no = b.oth_orderno
    WHERE a.pt = '${-1d_pt}'
        AND a.order_type = 16  -- 维修订单
        AND a.label_group NOT IN ('8','1','25')  -- 排除检修等
        AND a.lease_status IN (2,3)  -- 租赁状态（租后维修）
        AND a.city_name = '北京市'  -- 北京市
        AND SUBSTR(a.order_create_time, 1, 10) BETWEEN '2026-01-12' AND '2026-01-15'  -- 2026年1月12日-15日
        AND a.first_sign_time IS NOT NULL  -- 有签到记录
        AND a.first_sign_time != '1000-01-01 00:00:00'  -- 排除默认值（未签到）
),

-- 2. 统计每个订单的改约次数
order_change_stats AS (
    SELECT 
        service_order_code,
        COUNT(*) AS change_count  -- 改约次数
    FROM dw.dw_fas_jiafu_dispatch_service_order_operate_history_da
    WHERE pt = '${-1d_pt}'
        AND operate_type_name = '修改服务时间'
    GROUP BY service_order_code
),

-- 3. 关联订单信息和改约信息
order_detail AS (
    SELECT 
        b.service_order_code,
        b.order_no,
        b.city_name,
        b.order_date,
        b.first_sign_time,
        b.service_start_time,  -- 预约服务开始时间
        b.modified_service_start_time,  -- 修改后的服务开始时间（最后一次修改）
        b.order_create_time,
        COALESCE(c.change_count, 0) AS change_count,  -- 改约次数，没有改约则为0
        -- 判断首次签到时间是否小于等于修改后的服务开始时间（已排除未签到的订单）
        CASE 
            WHEN b.modified_service_start_time IS NOT NULL 
                AND b.first_sign_time <= b.modified_service_start_time 
            THEN 1 
            ELSE 0 
        END AS is_sign_before_changed_time,
        -- 计算预约服务开始时间和修改后服务开始时间的时间差（小时）
        CASE 
            WHEN b.modified_service_start_time IS NOT NULL 
                AND b.service_start_time IS NOT NULL
            THEN 
                (unix_timestamp(b.modified_service_start_time) - unix_timestamp(b.service_start_time)) / 3600.0
            ELSE NULL
        END AS time_diff_hours
    FROM base_orders b
    LEFT JOIN order_change_stats c
        ON b.service_order_code = c.service_order_code
)

-- 4. 按日期聚合统计
SELECT 
    order_date AS `日期`,
    COUNT(DISTINCT service_order_code) AS `签到单量`,
    COUNT(DISTINCT CASE WHEN is_sign_before_changed_time = 1 THEN service_order_code END) AS `首次签到时间≤修改后服务开始时间的单量`,
    CONCAT(
        ROUND(
            COUNT(DISTINCT CASE WHEN is_sign_before_changed_time = 1 THEN service_order_code END) * 100.0 
            / NULLIF(COUNT(DISTINCT service_order_code), 0), 
            2
        ), 
        '%'
    ) AS `占比`,
    -- 预约服务开始时间和修改后服务开始时间平均相差多少小时
    ROUND(AVG(time_diff_hours), 2) AS `预约时间与修改后时间平均时间差(小时)`,
    -- 下单后的平均改约次数
    ROUND(AVG(change_count), 2) AS `平均改约次数`,
    -- 有改约的单量
    COUNT(DISTINCT CASE WHEN change_count > 0 THEN service_order_code END) AS `有改约的单量`,
    -- 改约率
    CONCAT(
        ROUND(
            COUNT(DISTINCT CASE WHEN change_count > 0 THEN service_order_code END) * 100.0 
            / NULLIF(COUNT(DISTINCT service_order_code), 0), 
            2
        ), 
        '%'
    ) AS `改约率`
FROM order_detail
GROUP BY order_date
ORDER BY order_date
;
