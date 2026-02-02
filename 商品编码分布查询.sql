-- 查询实际的商品编码分布，用于调试维修类型匹配问题
-- 查看24年12月24日-25年3月18日期间的商品编码
SELECT 
    b.commodity_code AS `商品编码`,
    b.commodity_name AS `商品名称`,
    COUNT(DISTINCT a.order_no) AS `订单数`,
    COUNT(DISTINCT a.service_order_professional_ucid) AS `维修人数`,
    CASE 
        WHEN b.commodity_code IN (
            'CM00300000048611', 'CM00300000035381', 'CM00300000031856', 'CM00300000015322', 
            'CM00300000011582', 'CM00300001615920', 'CM00300000472146', 'CM00300000045028', 
            'CM00300000042537', 'CM00300000033348', 'CM00300000030730', 'CM00300000023281', 
            'CM00300000017957', 'CM00300000014849', 'CM00300000009439', 'CM00300002378666', 
            'CM00300000471848', 'CM00300002379296', 'CM00300000128429', 'CM00300000044135', 
            'CM00300000041205', 'CM00300000032923', 'CM00300000029123', 'CM00300000016932', 
            'CM00300000012090', 'CM00300000478370', 'CM00300001070862', 'CM00300000474070'
        ) THEN '维修综合'
        WHEN b.commodity_code IN (
            'CM00300000480465', 'CM00300000043776', 'CM00300000028473', 'CM00300000018922', 
            'CM00300000224171', 'CM00300000019427', 'CM00300000006039'
        ) THEN '维修家电'
        ELSE '其他'
    END AS `维修类型`
FROM (
    SELECT DISTINCT
        order_no,
        order_create_time,
        service_order_professional_ucid,
        label_group,
        lease_status,
        performance_mode
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${-1d_pt}'
    AND order_type = 16
    AND label_group NOT IN ('8')
    AND to_date(order_create_time) BETWEEN '2024-12-24' AND '2025-03-18'
    AND service_order_professional_ucid IS NOT NULL
    AND service_order_professional_ucid != -911
) a
INNER JOIN (
    SELECT DISTINCT
        order_no,
        commodity_code,
        commodity_name
    FROM olap.olap_hj_fas_main_order_commodity_da
    WHERE pt = '${-1d_pt}'
    AND commodity_type = 1  -- 1:下单商品
    AND order_no IS NOT NULL
    AND commodity_code IS NOT NULL
) b ON b.order_no = a.order_no
GROUP BY 
    b.commodity_code,
    b.commodity_name,
    CASE 
        WHEN b.commodity_code IN (
            'CM00300000048611', 'CM00300000035381', 'CM00300000031856', 'CM00300000015322', 
            'CM00300000011582', 'CM00300001615920', 'CM00300000472146', 'CM00300000045028', 
            'CM00300000042537', 'CM00300000033348', 'CM00300000030730', 'CM00300000023281', 
            'CM00300000017957', 'CM00300000014849', 'CM00300000009439', 'CM00300002378666', 
            'CM00300000471848', 'CM00300002379296', 'CM00300000128429', 'CM00300000044135', 
            'CM00300000041205', 'CM00300000032923', 'CM00300000029123', 'CM00300000016932', 
            'CM00300000012090', 'CM00300000478370', 'CM00300001070862', 'CM00300000474070'
        ) THEN '维修综合'
        WHEN b.commodity_code IN (
            'CM00300000480465', 'CM00300000043776', 'CM00300000028473', 'CM00300000018922', 
            'CM00300000224171', 'CM00300000019427', 'CM00300000006039'
        ) THEN '维修家电'
        ELSE '其他'
    END
ORDER BY `订单数` DESC
LIMIT 100
