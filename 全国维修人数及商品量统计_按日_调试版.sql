-- 调试版本：查看维修类型分布和数据关联情况
-- 统计24年12月24日-25年3月18日每天全国维修人数及商品量
SELECT 
    to_date(a.order_create_time) AS `日期`,
    
    -- ========== 维修人数统计 ==========
    COUNT(DISTINCT a.service_order_professional_ucid) AS `总维修人数`,
    COUNT(DISTINCT CASE WHEN b.`维修类型` = '维修综合' THEN a.service_order_professional_ucid END) AS `综合维修人数`,
    COUNT(DISTINCT CASE WHEN b.`维修类型` = '维修家电' THEN a.service_order_professional_ucid END) AS `家电维修人数`,
    COUNT(DISTINCT CASE WHEN b.`维修类型` = '其他' THEN a.service_order_professional_ucid END) AS `其他类型维修人数`,
    COUNT(DISTINCT CASE WHEN b.`维修类型` IS NULL THEN a.service_order_professional_ucid END) AS `未匹配商品的维修人数`,
    
    -- ========== 订单数统计（调试用） ==========
    COUNT(DISTINCT a.order_no) AS `总订单数`,
    COUNT(DISTINCT CASE WHEN b.order_no IS NOT NULL THEN a.order_no END) AS `匹配到商品的订单数`,
    COUNT(DISTINCT CASE WHEN b.order_no IS NULL THEN a.order_no END) AS `未匹配到商品的订单数`,
    
    -- ========== 商品量统计（调试用） ==========
    COUNT(DISTINCT CONCAT(a.order_no, '-', b.commodity_code)) AS `总商品关联数`,
    COUNT(DISTINCT CASE WHEN b.`维修类型` = '维修综合' THEN CONCAT(a.order_no, '-', b.commodity_code) END) AS `综合类商品数`,
    COUNT(DISTINCT CASE WHEN b.`维修类型` = '维修家电' THEN CONCAT(a.order_no, '-', b.commodity_code) END) AS `家电类商品数`,
    COUNT(DISTINCT CASE WHEN b.`维修类型` = '其他' THEN CONCAT(a.order_no, '-', b.commodity_code) END) AS `其他类商品数`,
    
    -- ========== 租期维修商品量统计 ==========
    COUNT(DISTINCT CASE 
        WHEN a.label_group NOT IN ('1', '8', '25') 
        AND a.lease_status IN (2, 3)
        THEN CONCAT(a.order_no, '-', b.commodity_code)
    END) AS `租期维修总商品量`,
    
    COUNT(DISTINCT CASE 
        WHEN a.label_group NOT IN ('1', '8', '25') 
        AND a.lease_status IN (2, 3)
        AND b.`维修类型` = '维修综合'
        THEN CONCAT(a.order_no, '-', b.commodity_code)
    END) AS `租期维修综合商品量`,
    
    COUNT(DISTINCT CASE 
        WHEN a.label_group NOT IN ('1', '8', '25') 
        AND a.lease_status IN (2, 3)
        AND b.`维修类型` = '维修家电'
        THEN CONCAT(a.order_no, '-', b.commodity_code)
    END) AS `租期维修家电商品量`,
    
    -- ========== 检修维修商品量统计 ==========
    COUNT(DISTINCT CASE 
        WHEN a.label_group IN ('1', '25')
        THEN CONCAT(a.order_no, '-', b.commodity_code)
    END) AS `检修总商品量`,
    
    COUNT(DISTINCT CASE 
        WHEN a.label_group IN ('1', '25')
        AND b.`维修类型` = '维修综合'
        THEN CONCAT(a.order_no, '-', b.commodity_code)
    END) AS `检修综合商品量`,
    
    COUNT(DISTINCT CASE 
        WHEN a.label_group IN ('1', '25')
        AND b.`维修类型` = '维修家电'
        THEN CONCAT(a.order_no, '-', b.commodity_code)
    END) AS `检修家电商品量`,
    
    -- ========== 紧急商品量统计 ==========
    COUNT(DISTINCT CASE 
        WHEN a.performance_mode IN (1, 2)  -- 1=紧急单, 2=加急单
        THEN CONCAT(a.order_no, '-', b.commodity_code)
    END) AS `紧急商品量`
    
FROM (
    SELECT DISTINCT
        order_no,
        order_create_time,
        service_order_professional_ucid,
        service_order_professional_name,
        label_group,
        lease_status,
        performance_mode,
        service_order_code
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${-1d_pt}'
    AND order_type = 16
    AND label_group NOT IN ('8')  -- 排除标签组8
    AND to_date(order_create_time) BETWEEN '2024-12-24' AND '2025-03-18'
    AND service_order_professional_ucid IS NOT NULL
    AND service_order_professional_ucid != -911  -- 排除异常UCID
) a
LEFT JOIN (  -- 改为LEFT JOIN，避免过滤掉主表数据
    SELECT DISTINCT
        order_no,
        service_order_code,
        commodity_code,
        commodity_name,
        CASE 
            WHEN commodity_code IN (
                'CM00300000048611', 'CM00300000035381', 'CM00300000031856', 'CM00300000015322', 
                'CM00300000011582', 'CM00300001615920', 'CM00300000472146', 'CM00300000045028', 
                'CM00300000042537', 'CM00300000033348', 'CM00300000030730', 'CM00300000023281', 
                'CM00300000017957', 'CM00300000014849', 'CM00300000009439', 'CM00300002378666', 
                'CM00300000471848', 'CM00300002379296', 'CM00300000128429', 'CM00300000044135', 
                'CM00300000041205', 'CM00300000032923', 'CM00300000029123', 'CM00300000016932', 
                'CM00300000012090', 'CM00300000478370', 'CM00300001070862', 'CM00300000474070'
            ) THEN '维修综合'
            WHEN commodity_code IN (
                'CM00300000480465', 'CM00300000043776', 'CM00300000028473', 'CM00300000018922', 
                'CM00300000224171', 'CM00300000019427', 'CM00300000006039'
            ) THEN '维修家电'
            ELSE '其他'
        END AS `维修类型`
    FROM olap.olap_hj_fas_main_order_commodity_da
    WHERE pt = '${-1d_pt}'
    AND commodity_type = 1  -- 1:下单商品
    AND order_no IS NOT NULL
    AND commodity_code IS NOT NULL
) b ON b.order_no = a.order_no
GROUP BY to_date(a.order_create_time)
ORDER BY `日期`
