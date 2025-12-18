-- 健康度暂不维修统计
-- 根据 rpt.rpt_jiankandumingxi1 表统计

SELECT 
    month_string AS `月份`,
    city_name AS `城市`,
    COUNT(DISTINCT CASE 
        WHEN service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        THEN service_order_code 
    END) AS `总完工单量`,
    COUNT(DISTINCT CASE 
        WHEN service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND rea = '是' 
        THEN service_order_code 
    END) AS `标记暂不维修单量`,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN service_order_complete_time IS NOT NULL 
            AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
            AND rea = '是' 
            THEN service_order_code 
        END) * 100.0 / 
        NULLIF(COUNT(DISTINCT CASE 
            WHEN service_order_complete_time IS NOT NULL 
            AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
            THEN service_order_code 
        END), 0), 
        2
    ) AS `暂不维修占比`,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN service_order_complete_time IS NOT NULL 
            AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
            AND label_group11 = '检修' 
            AND rea = '是' 
            THEN service_order_code 
        END) * 100.0 / 
        NULLIF(COUNT(DISTINCT CASE 
            WHEN service_order_complete_time IS NOT NULL 
            AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
            AND label_group11 = '检修' 
            THEN service_order_code 
        END), 0), 
        2
    ) AS `检修暂不维修占比`,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN service_order_complete_time IS NOT NULL 
            AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
            AND label_group11 = '租后维修' 
            AND rea = '是' 
            THEN service_order_code 
        END) * 100.0 / 
        NULLIF(COUNT(DISTINCT CASE 
            WHEN service_order_complete_time IS NOT NULL 
            AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
            AND label_group11 = '租后维修' 
            THEN service_order_code 
        END), 0), 
        2
    ) AS `租期暂不维修占比`,
    COUNT(DISTINCT CASE 
        WHEN service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND label_group11 = '检修' 
        THEN service_order_code 
    END) AS `检修-单量`,
    COUNT(DISTINCT CASE 
        WHEN service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND label_group11 = '租后维修' 
        THEN service_order_code 
    END) AS `租后-单量`,
    COUNT(DISTINCT CASE 
        WHEN service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND label_group11 = '检修' 
        AND rea = '是' 
        THEN service_order_code 
    END) AS `检修-暂不维修量`,
    COUNT(DISTINCT CASE 
        WHEN service_order_complete_time IS NOT NULL 
        AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000') 
        AND label_group11 = '租后维修' 
        AND rea = '是' 
        THEN service_order_code 
    END) AS `租后-暂不维修量`
FROM rpt.rpt_jiankandumingxi1
WHERE pt = '${-1d_pt}'
GROUP BY month_string, city_name
ORDER BY month_string DESC, city_name;

