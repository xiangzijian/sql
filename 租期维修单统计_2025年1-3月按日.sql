-- 2025年全国1月-3月租期维修单统计，按城市和日期分组
SELECT 
    to_date(a.order_create_time) AS `创建日期`,
    CASE 
        WHEN a.city_name = '北京市' AND a.manager_marketing_name IN ('京东事业部','京东南事业部','京东南租赁运营部','京东南运营','京东运营','京南事业部','京南大部','京南运营','京西南事业部','京西南运营') 
        THEN '惠居京南'
        WHEN a.city_name = '北京市' AND a.manager_marketing_name IN ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营') 
        THEN '惠居京北'
        ELSE a.city_name
    END AS `城市`,
    -- 租期维修单总数
    COUNT(DISTINCT a.order_no) AS `租期维修单总数`,
    -- 24小时完工数
    COUNT(DISTINCT CASE 
        WHEN a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND (unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24 
        THEN a.order_no 
    END) AS `24小时完工数`,
    -- 24小时上门数
    COUNT(DISTINCT CASE 
        WHEN a.first_sign_time IS NOT NULL 
        AND SUBSTR(a.first_sign_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND (unix_timestamp(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24 
        THEN a.order_no 
    END) AS `24小时上门数`,
    -- 24小时完单数
    COUNT(DISTINCT CASE 
        WHEN a.order_complete_time IS NOT NULL 
        AND SUBSTR(a.order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND (unix_timestamp(a.order_complete_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24 
        THEN a.order_no 
    END) AS `24小时完单数`,
    -- 1小时致电数
    COUNT(DISTINCT CASE 
        WHEN (a.is_not = 1 
              OR (SUBSTR(a.first_call_time, 1, 4) >= '2000' 
                  AND (unix_timestamp(a.first_call_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60))
        AND (a.cancel_time = '1000-01-01 00:00:00' 
             OR (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 > 60)
        THEN a.order_no 
    END) AS `1小时致电数`,
    -- 5日完工数
    COUNT(DISTINCT CASE 
        WHEN a.is_in5day_complete = 1
        THEN a.order_no 
    END) AS `5日完工数`,
    -- 已完工数
    COUNT(DISTINCT CASE 
        WHEN a.service_order_complete_time IS NOT NULL 
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        THEN a.order_no 
    END) AS `已完工数`,
    -- 已完单数
    COUNT(DISTINCT CASE 
        WHEN a.order_complete_time IS NOT NULL 
        AND SUBSTR(a.order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        THEN a.order_no 
    END) AS `已完单数`,
    -- 剔除1小时取消的租期维修单数
    COUNT(DISTINCT CASE 
        WHEN a.cancel_time = '1000-01-01 00:00:00' 
             OR (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss') - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 > 60
        THEN a.order_no 
    END) AS `剔除1小时取消订单数`
FROM (
    SELECT  
        order_no,
        order_create_time,
        service_order_complete_time,
        first_sign_time,
        first_call_time,
        order_complete_time,
        cancel_time,
        city_name,
        manager_marketing_name,
        manager_area_name,
        service_order_supplier_name,
        service_order_code,
        label_group,
        lease_status,
        is_in5day_complete,
        CASE
            WHEN SUBSTR(order_create_time, 12, 2) >= '21'
                 AND first_call_time < CONCAT(date_add(to_date(order_create_time), 1), ' 10:00:00')
                 AND SUBSTR(first_call_time, 1, 4) >= '2000'
            THEN 1
            WHEN SUBSTR(order_create_time, 12, 2) < '09'
                 AND first_call_time < CONCAT(to_date(order_create_time), ' 10:00:00')
                 AND SUBSTR(first_call_time, 1, 4) >= '2000'
            THEN 1
            ELSE 0
        END AS is_not
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${-1d_pt}'
    AND order_type = 16
    AND label_group NOT IN ('1', '8', '25')  -- 排除检修
    AND lease_status IN (2, 3)  -- 租期维修
    AND SUBSTR(order_create_time, 1, 7) IN ('2025-01', '2025-02', '2025-03')  -- 2025年1-3月
) a
INNER JOIN (
    SELECT
        order_no AS oth_orderno,
        create_time
    FROM rpt.rpt_fas_light_hosting_order_detail_da
    WHERE pt = '${-1d_pt}'
    AND vison_type = '4.0'
    AND service_name IN ('维修','燃气')
    AND order_type = '16'
    AND label_group NOT IN ('8')
    AND commodity_name_list1 != '漏水专项检修'
    AND commodity_code_list1 != 'SCM00300001672373'
    AND commodity_name_list1 NOT IN ('夏季空调预检','消防器材','定损','漏水定损','火灾定损','其他定损','京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')
    AND supplier_name NOT IN (
        '上海兰宫建筑装饰有限公司',
        '上海尚礼实业有限公司',
        '上海苏皖贸易有限公司',
        '上海再旭保洁服务有限公司',
        '源和里仁家具海安有限公司',
        '匠云（北京）科技有限公司'
    )
) b ON b.oth_orderno = a.order_no
GROUP BY 
    to_date(a.order_create_time),
    CASE 
        WHEN a.city_name = '北京市' AND a.manager_marketing_name IN ('京东事业部','京东南事业部','京东南租赁运营部','京东南运营','京东运营','京南事业部','京南大部','京南运营','京西南事业部','京西南运营') 
        THEN '惠居京南'
        WHEN a.city_name = '北京市' AND a.manager_marketing_name IN ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营') 
        THEN '惠居京北'
        ELSE a.city_name
    END
ORDER BY `创建日期`, `城市`
