-- 2025-2026年每月城市报修服务单编码及商品统计
-- 区分检修和租期维修
-- 说明：与健康度.sql保持一致，过滤掉漏水定损、特定供应商等订单
WITH numbers AS (
    SELECT
        CONCAT(year_string, '-', LPAD(n, 2, '0')) AS month_string,
        city_name
    FROM
        (SELECT n, city_name, year_string
         FROM
           (SELECT stack(12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) AS n) t1  
         LATERAL VIEW EXPLODE(
           ARRAY('上海市', '天津市', '成都市', '杭州市', '苏州市', '宁波市', '深圳市', '济南市', '广州市', '西安市', '武汉市', '南京市','惠居京北','惠居京南')
         ) t2 AS city_name
         LATERAL VIEW EXPLODE(
           ARRAY('2025', '2026')
         ) t3 AS year_string
        ) t
)

SELECT 
    a.city_name AS `城市`,
    SUBSTR(a.order_create_time, 1, 7) AS `月份`,
    
    -- 检修统计
    COUNT(DISTINCT CASE 
        WHEN a.label_group IN ('1','25') 
        THEN a.service_order_code 
    END) AS `检修服务单编码数量`,
    
    COUNT(DISTINCT CASE 
        WHEN a.label_group IN ('1','25') 
        THEN CONCAT(a.service_order_code, '-', b.commodity_name) 
    END) AS `检修商品数量`,
    
    -- 租期维修统计
    COUNT(DISTINCT CASE 
        WHEN a.label_group NOT IN ('1','8','25') 
        AND a.lease_status IN (2, 3)
        THEN a.service_order_code 
    END) AS `租期维修服务单编码数量`,
    
    COUNT(DISTINCT CASE 
        WHEN a.label_group NOT IN ('1','8','25') 
        AND a.lease_status IN (2, 3)
        THEN CONCAT(a.service_order_code, '-', b.commodity_name) 
    END) AS `租期维修商品数量`,
    
    -- 总计
    COUNT(DISTINCT a.service_order_code) AS `总服务单编码数量`,
    COUNT(DISTINCT CONCAT(a.service_order_code, '-', b.commodity_name)) AS `总商品数量`
    
FROM 
    (
        SELECT DISTINCT 
            a.order_no,
            a.service_order_code,
            a.order_create_time,
            a.label_group,
            a.lease_status,
            a.manager_marketing_name,
            CASE
                WHEN a.city_name = '北京市' 
                     AND a.manager_marketing_name IN ('京东事业部','京东南事业部','京东南租赁运营部','京东南运营','京东运营','京南事业部','京南大部','京南运营','京西南事业部','京西南运营') 
                THEN '惠居京南'
                WHEN a.city_name = '北京市' 
                     AND a.manager_marketing_name IN ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营') 
                THEN '惠居京北'
                ELSE a.city_name
            END AS city_name            
        FROM olap.olap_hj_fas_main_order_service_info_da a
        -- 关键：与健康度.sql保持一致，INNER JOIN过滤条件
        INNER JOIN (
            SELECT
                order_no as oth_orderno,
                create_time,
                order_after_sign_diff_out,
                CASE WHEN service_time_end > original_service_time_end 
                     THEN service_time_end 
                     ELSE original_service_time_end 
                END AS final_time  -- 取预约服务时间和实际服务时间最新的
            FROM rpt.rpt_fas_light_hosting_order_detail_da
            WHERE pt = '${-1d_pt}'
                AND vison_type = '4.0'
                -- AND order_after_sign_diff_out >= '0'  -- 出房签约后
                AND service_name IN ('维修','燃气')
                AND order_type = '16'
                AND label_group NOT IN ('8')  -- 排除门锁
                AND commodity_name_list1 != '漏水专项检修'  -- 2024-12-24漏水coe剔除
                AND commodity_name_list1 NOT IN ('夏季空调预检','SCM00300001672373','漏水专项检修','消防器材','定损','漏水定损','火灾定损','其他定损','京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')
                AND supplier_name NOT IN ('上海兰宫建筑装饰有限公司','上海尚礼实业有限公司','上海苏皖贸易有限公司','上海再旭保洁服务有限公司','源和里仁家具海安有限公司','匠云（北京）科技有限公司')
        ) rpt_detail ON rpt_detail.oth_orderno = a.order_no
        WHERE a.pt = '${-1d_pt}'
            AND a.order_type = 16  -- 轻托管维修单
            AND a.label_group NOT IN ('8')  -- 排除门锁工单
            AND a.service_order_code IS NOT NULL
    ) AS a
    
LEFT JOIN 
    (
        SELECT DISTINCT
            order_no,
            commodity_name,
            commodity_code,
            commodity_type
        FROM olap.olap_hj_fas_main_order_commodity_da
        WHERE pt = '${-1d_pt}'
            AND commodity_type = 1  -- 下单商品
    ) AS b
    ON a.order_no = b.order_no

INNER JOIN numbers
    ON numbers.city_name = a.city_name
    AND SUBSTR(a.order_create_time, 1, 7) = numbers.month_string

WHERE numbers.month_string <= SUBSTR(CURRENT_DATE, 1, 7)  -- 只统计到当前月份

GROUP BY 
    a.city_name,
    SUBSTR(a.order_create_time, 1, 7)

ORDER BY 
    a.city_name,
    SUBSTR(a.order_create_time, 1, 7)
