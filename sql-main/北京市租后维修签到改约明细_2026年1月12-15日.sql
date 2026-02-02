-- 北京市2026年1月12日-15日租后维修单签到和改约明细表（含未签到订单）
-- 用于核对每个订单的签到时间、改约情况、时间差等详细信息
-- 包含未签到的订单
-- 更新日期：2026-01-16

WITH
-- 1. 获取北京市2026年1月12日-15日租后维修单的基础信息
base_orders AS (
    SELECT DISTINCT
        a.service_order_code,
        a.order_no,
        a.city_name,
        a.manager_marketing_name,
        a.manager_area_name,
        a.service_order_supplier_name,
        a.service_order_professional_name,
        a.first_sign_time,  -- 首次签到时间
        a.service_start_time,  -- 预约服务开始时间
        a.modified_service_start_time,  -- 修改后的服务开始时间（最后一次修改）
        a.order_create_time,
        a.service_order_complete_time,
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
        -- 不再限制必须有签到记录，包含未签到的订单
),

-- 2. 获取商品信息
order_products AS (
    SELECT 
        service_order_code,
        concat_ws(',', collect_set(product_name)) AS product_names  -- 商品名称（多个商品用逗号分隔）
    FROM dw.dw_fas_jiafu_dispatch_service_order_product_da
    WHERE pt = '${-1d_pt}'
        AND product_name IS NOT NULL
    GROUP BY service_order_code
),

-- 3. 统计每个订单的改约次数
order_change_stats AS (
    SELECT 
        service_order_code,
        COUNT(*) AS change_count  -- 改约次数
    FROM dw.dw_fas_jiafu_dispatch_service_order_operate_history_da
    WHERE pt = '${-1d_pt}'
        AND operate_type_name = '修改服务时间'
    GROUP BY service_order_code
)

-- 4. 明细表输出
SELECT 
    b.order_date AS `订单日期`,
    b.service_order_code AS `服务单编码`,
    b.order_no AS `订单号`,
    b.city_name AS `城市`,
    b.manager_marketing_name AS `营销大区`,
    b.manager_area_name AS `业务区域`,
    b.service_order_supplier_name AS `供应商`,
    b.service_order_professional_name AS `服务者`,
    p.product_names AS `商品名称`,
    b.order_create_time AS `订单创建时间`,
    b.service_start_time AS `预约服务开始时间`,
    b.modified_service_start_time AS `修改后服务开始时间`,
    b.first_sign_time AS `首次签到时间`,
    b.service_order_complete_time AS `完工时间`,
    
    -- 是否签到（排除默认值1000-01-01 00:00:00）
    CASE 
        WHEN b.first_sign_time IS NOT NULL 
            AND b.first_sign_time != '1000-01-01 00:00:00' 
        THEN '是' 
        ELSE '否' 
    END AS `是否签到`,
    
    -- 改约次数
    COALESCE(c.change_count, 0) AS `改约次数`,
    
    -- 判断是否有改约
    CASE 
        WHEN c.change_count > 0 THEN '是' 
        ELSE '否' 
    END AS `是否改约`,
    
    -- 判断首次签到时间是否小于等于修改后的服务开始时间（排除未签到的情况）
    CASE 
        WHEN b.modified_service_start_time IS NOT NULL 
            AND b.first_sign_time IS NOT NULL
            AND b.first_sign_time != '1000-01-01 00:00:00'
            AND b.first_sign_time <= b.modified_service_start_time 
        THEN '是' 
        WHEN b.first_sign_time IS NULL OR b.first_sign_time = '1000-01-01 00:00:00'
        THEN '未签到'
        ELSE '否' 
    END AS `首次签到≤修改后服务开始时间`,
    
    -- 预约服务时间与修改后服务时间的时间差（小时）
    CASE 
        WHEN b.modified_service_start_time IS NOT NULL 
            AND b.service_start_time IS NOT NULL
        THEN 
            ROUND((unix_timestamp(b.modified_service_start_time) - unix_timestamp(b.service_start_time)) / 3600.0, 2)
        ELSE NULL
    END AS `预约时间与修改后时间差(小时)`,
    
    -- 签到时间与预约时间的时间差（小时）（排除未签到）
    CASE 
        WHEN b.first_sign_time IS NOT NULL 
            AND b.first_sign_time != '1000-01-01 00:00:00'
            AND b.service_start_time IS NOT NULL
        THEN 
            ROUND((unix_timestamp(b.first_sign_time) - unix_timestamp(b.service_start_time)) / 3600.0, 2)
        ELSE NULL
    END AS `签到时间与预约时间差(小时)`,
    
    -- 签到时间与修改后服务时间的时间差（小时）（排除未签到）
    CASE 
        WHEN b.first_sign_time IS NOT NULL 
            AND b.first_sign_time != '1000-01-01 00:00:00'
            AND b.modified_service_start_time IS NOT NULL
        THEN 
            ROUND((unix_timestamp(b.first_sign_time) - unix_timestamp(b.modified_service_start_time)) / 3600.0, 2)
        ELSE NULL
    END AS `签到时间与修改后时间差(小时)`
    
FROM base_orders b
LEFT JOIN order_products p
    ON b.service_order_code = p.service_order_code
LEFT JOIN order_change_stats c
    ON b.service_order_code = c.service_order_code
ORDER BY 
    b.order_date,
    b.order_create_time
;
