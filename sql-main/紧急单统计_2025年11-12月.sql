-- 紧急单统计：计算2025年11月-12月各城市的紧急单分母和分子
-- 紧急单分母(is_urgent1): 所有紧急订单数量
-- 紧急单分子(is_urgent2): 2小时内上门的紧急订单数量

WITH numbers AS (
    SELECT
        CONCAT(year_string, '-', LPAD(n, 2, '0')) AS month_string,
        city_name
    FROM
        (SELECT n, city_name, year_string
         FROM
           (SELECT stack(2, 11, 12) AS n) t1  -- 只生成11月和12月
         LATERAL VIEW EXPLODE(
           ARRAY('上海市', '天津市', '成都市', '杭州市', '苏州市', '宁波市', '深圳市', '济南市', '广州市', '西安市', '武汉市', '南京市','惠居京北','惠居京南')
         ) t2 AS city_name
         LATERAL VIEW EXPLODE(
           ARRAY('2025')  -- 只查询2025年
         ) t3 AS year_string
        ) t
)

SELECT 
    numbers.city_name AS `城市`,
    SUBSTR(numbers.month_string, 1, 7) AS `月份`,
    -- 紧急单分母：所有紧急订单数量
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(kk.order_create_time, 1, 7) 
        THEN kk.`总订单` 
    END) AS `紧急单分母(is_urgent1)`,
    
    -- 紧急单分子：2小时内上门的紧急订单数量
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(kk.order_create_time, 1, 7) 
        THEN kk.`2h上门` 
    END) AS `紧急单分子(is_urgent2)`,
    
    -- 紧急30分钟致电单（额外统计）
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(kk.order_create_time, 1, 7) 
        THEN kk.`紧急30分钟致电单` 
    END) AS `紧急30分钟致电单数`,
    
    -- 计算紧急单2小时上门率
    CASE 
        WHEN COUNT(DISTINCT CASE 
            WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(kk.order_create_time, 1, 7) 
            THEN kk.`总订单` 
        END) > 0 
        THEN ROUND(
            COUNT(DISTINCT CASE 
                WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(kk.order_create_time, 1, 7) 
                THEN kk.`2h上门` 
            END) * 100.0 / 
            COUNT(DISTINCT CASE 
                WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(kk.order_create_time, 1, 7) 
                THEN kk.`总订单` 
            END), 2
        )
        ELSE 0 
    END AS `2小时上门率(%)`
    
FROM numbers
LEFT JOIN (
    SELECT DISTINCT 
        order_create_time,    
        order_no as order_no_1,
        CASE 
            WHEN city_name = '北京市' THEN manager_corp_name 
            ELSE city_name  
        END AS `city_name`,
        CASE 
            WHEN is_urgent_order = 1 OR is_urgent_switch = 1 
            THEN order_no  
        END AS `总订单`,
        CASE 
            WHEN is_2_hour_urgent_on_door = 1 
                AND (is_urgent_order = 1 OR is_urgent_switch = 1) 
            THEN order_no 
        END AS `2h上门`,
        CASE 
            WHEN is_30_min_urgent_call = 1 
                AND (is_urgent_order = 1 OR is_urgent_switch = 1) 
            THEN order_no 
        END AS `紧急30分钟致电单`
    FROM rpt.rpt_jiafu_urgent_order_info_da
    WHERE pt = '${-1d_pt}'
        AND SUBSTR(order_create_time, 1, 7) IN ('2025-11', '2025-12')  -- 只筛选2025年11-12月的数据
        AND (urgent_flag IN (1, 2) OR performance_mode IN (1, 2))
) kk 
    ON kk.city_name = numbers.city_name
WHERE numbers.month_string IN ('2025-11', '2025-12')  -- 只查询11月和12月
GROUP BY 
    numbers.city_name,
    SUBSTR(numbers.month_string, 1, 7)
ORDER BY 
    SUBSTR(numbers.month_string, 1, 7),
    numbers.city_name
