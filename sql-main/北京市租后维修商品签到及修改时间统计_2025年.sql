-- 北京市2025年租后维修单按商品聚合的签到单量和签到后修改服务时间单量统计
-- 数据来源：olap.olap_hj_fas_main_order_service_info_da、dw.dw_fas_jiafu_dispatch_service_order_product_da、dw.dw_fas_jiafu_dispatch_service_order_operate_history_da
-- 更新日期：2026-01-16

WITH
-- 1. 获取北京市2025年租后维修单的签到信息
base_orders AS (
    SELECT DISTINCT
        a.service_order_code,
        a.order_no,
        a.city_name,
        a.first_sign_time,  -- 首次签到时间
        a.order_create_time
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
            AND commodity_name_list1 != '漏水专项检修'  -- 排除漏水
            AND commodity_name_list1 NOT IN ('夏季空调预检','SCM00300001672373','漏水专项检修','消防器材','定损','漏水定损','火灾定损','其他定损','京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')
            AND supplier_name NOT IN ('上海兰宫建筑装饰有限公司','上海尚礼实业有限公司','上海苏皖贸易有限公司','上海再旭保洁服务有限公司','源和里仁家具海安有限公司','匠云（北京）科技有限公司')
    ) b ON a.order_no = b.oth_orderno
    WHERE a.pt = '${-1d_pt}'
        AND a.order_type = 16  -- 维修订单
        AND a.label_group NOT IN ('8','1','25')  -- 排除检修等
        AND a.lease_status IN (2,3)  -- 租赁状态（租后维修）
        AND a.city_name = '北京市'  -- 北京市
        AND SUBSTR(a.order_create_time, 1, 7) BETWEEN '2025-01' AND '2025-12'  -- 2025年
        AND a.first_sign_time IS NOT NULL  -- 有签到记录
),

-- 2. 获取商品信息
order_products AS (
    SELECT DISTINCT
        service_order_code,
        product_name,
        product_code
    FROM dw.dw_fas_jiafu_dispatch_service_order_product_da
    WHERE pt = '${-1d_pt}'
        AND product_name IS NOT NULL
),

-- 3. 获取修改服务时间的操作记录
service_time_change AS (
    SELECT DISTINCT
        service_order_code,
        operate_time,
        operate_type_name
    FROM dw.dw_fas_jiafu_dispatch_service_order_operate_history_da
    WHERE pt = '${-1d_pt}'
        AND operate_type_name = '修改服务时间'
),

-- 4. 关联订单、商品和操作记录
order_detail AS (
    SELECT 
        b.service_order_code,
        b.order_no,
        b.city_name,
        b.first_sign_time,
        p.product_name,
        p.product_code,
        c.operate_time AS change_service_time,
        -- 判断是否在签到后修改服务时间
        CASE 
            WHEN c.operate_time IS NOT NULL 
                AND c.operate_time > b.first_sign_time 
            THEN 1 
            ELSE 0 
        END AS is_change_after_sign
    FROM base_orders b
    INNER JOIN order_products p
        ON b.service_order_code = p.service_order_code
    LEFT JOIN service_time_change c
        ON b.service_order_code = c.service_order_code
)

-- 5. 按商品聚合统计
SELECT 
    product_name AS `商品名称`,
    COUNT(DISTINCT service_order_code) AS `签到单量`,  -- 签到单量
    COUNT(DISTINCT CASE WHEN is_change_after_sign = 1 THEN service_order_code END) AS `签到后修改服务时间单量`,  -- 签到后修改服务时间单量
    CONCAT(
        ROUND(
            COUNT(DISTINCT CASE WHEN is_change_after_sign = 1 THEN service_order_code END) * 100.0 
            / NULLIF(COUNT(DISTINCT service_order_code), 0), 
            2
        ), 
        '%'
    ) AS `签到后修改服务时间占比`
FROM order_detail
GROUP BY product_name
ORDER BY `签到单量` DESC
;
