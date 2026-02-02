SELECT
    SUBSTR(a.order_create_time, 1, 7) AS month_string,
    a.city_name,
    a.service_order_supplier_name AS supplier_name,
    -- 3天完工（72小时）
    COUNT(DISTINCT CASE 
        WHEN (unix_timestamp(service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 72
        AND service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        THEN a.order_no 
    END) AS `3天完工`,
    -- 三天完工检修
    COUNT(DISTINCT CASE 
        WHEN (unix_timestamp(service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 72
        AND service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND a.label_group IN ('1','25')  -- 检修订单
        THEN a.order_no 
    END) AS `三天完工检修`,
    -- 三天完工租后
    COUNT(DISTINCT CASE 
        WHEN (unix_timestamp(service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 72
        AND service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND a.label_group NOT IN ('1','8','25')  -- 租后订单
        AND a.lease_status IN (2, 3)  -- 租后状态
        THEN a.order_no 
    END) AS `三天完工租后`,
    -- 新增：总完工订单数 (totalfix_num)
    COUNT(DISTINCT CASE 
        WHEN service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        THEN a.order_no 
    END) AS `总完工`,
    -- 新增：总完工检修
    COUNT(DISTINCT CASE 
        WHEN service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND a.label_group IN ('1','25')  -- 检修订单
        THEN a.order_no 
    END) AS `总完工检修`,
    -- 新增：总完工租后
    COUNT(DISTINCT CASE 
        WHEN service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND a.label_group NOT IN ('1','8','25')  -- 租后订单
        AND a.lease_status IN (2, 3)  -- 租后状态
        THEN a.order_no 
    END) AS `总完工租后`
FROM 
(
    SELECT DISTINCT 
        order_no,
        order_create_time,
        service_order_complete_time,
        service_order_supplier_name,
        city_name,
        label_group,
        lease_status
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${-1d_pt}'
    AND order_type = 16
    AND label_group NOT IN ('8')
    AND city_name = '深圳市'  -- 只选择深圳
    AND SUBSTR(order_create_time, 1, 7) = '2025-11'  -- 只选择11月
) a
INNER JOIN 
(
    SELECT
        order_no AS oth_orderno
    FROM rpt.rpt_fas_light_hosting_order_detail_da
    WHERE pt = '${-1d_pt}'
    AND vison_type = '4.0'
    AND service_name IN ('维修','燃气')
    AND order_type = '16'
    AND label_group NOT IN ('8')
    AND commodity_name_list1 != '漏水专项检修'
    AND commodity_code_list1 != 'SCM00300001672373'
    AND commodity_name_list1 NOT IN ('夏季空调预检','消防器材')
    AND supplier_name NOT IN (
        '上海兰宫建筑装饰有限公司',
        '上海尚礼实业有限公司',
        '上海苏皖贸易有限公司',
        '上海再旭保洁服务有限公司',
        '源和里仁家具海安有限公司'
    )
) b ON a.order_no = b.oth_orderno
GROUP BY 
    SUBSTR(a.order_create_time, 1, 7),
    a.city_name,
    a.service_order_supplier_name
ORDER BY 
    month_string,
    supplier_name;