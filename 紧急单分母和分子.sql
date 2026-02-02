-- 紧急单统计：计算2025年6月-12月各城市的紧急单分母和分子（旧口径+新口径）
WITH numbers AS (
    SELECT
        CONCAT(year_string, '-', LPAD(n, 2, '0')) AS month_string,
        city_name
    FROM
        (SELECT n, city_name, year_string
         FROM
           (SELECT stack(7, 6, 7, 8, 9, 10, 11, 12) AS n) t1  -- 生成6月到12月
         LATERAL VIEW EXPLODE(
           ARRAY('上海市', '天津市', '成都市', '杭州市', '苏州市', '宁波市', '深圳市', '济南市', '广州市', '西安市', '武汉市', '南京市','北京市')
         ) t2 AS city_name
         LATERAL VIEW EXPLODE(
           ARRAY('2025')  -- 只查询2025年
         ) t3 AS year_string
        ) t
)

SELECT 
    numbers.city_name AS `城市`,
    SUBSTR(numbers.month_string, 1, 7) AS `月份`,
    
    -- ========== 旧口径 ==========
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(kk.order_create_time, 1, 7) 
        THEN kk.`总订单_旧口径` 
    END) AS `紧急单分母_旧口径`,
    
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(kk.order_create_time, 1, 7) 
        THEN kk.`2h上门_旧口径` 
    END) AS `紧急单分子_旧口径`,
    
    -- ========== 新口径（剔除夜间21点-9点的取消单） ==========
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(kk.order_create_time, 1, 7) 
        THEN kk.`总订单_新口径` 
    END) AS `总订单_新口径`,
    
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(numbers.month_string, 1, 7) = SUBSTR(kk.order_create_time, 1, 7) 
        THEN kk.`2h上门_新口径` 
    END) AS `2h上门_新口径`
    
FROM numbers
LEFT JOIN (
    SELECT DISTINCT 
        t1.order_create_time,    
        t1.order_no as order_no_1,
        CASE 
            WHEN t1.city_name = '北京市' THEN t1.manager_corp_name 
            ELSE t1.city_name  
        END AS `city_name`,
        
        -- ========== 旧口径字段 ==========
        CASE 
            WHEN t1.is_urgent_order = 1 OR t1.is_urgent_switch = 1 
            THEN t1.order_no  
        END AS `总订单_旧口径`,
        
        CASE 
            WHEN t1.is_2_hour_urgent_on_door = 1 
                AND (t1.is_urgent_order = 1 OR t1.is_urgent_switch = 1) 
            THEN t1.order_no 
        END AS `2h上门_旧口径`,
        
        -- ========== 新口径字段（剔除order_status=50且夜间21点-9点的取消单） ==========
        CASE 
            WHEN (t1.is_urgent_order = 1 OR t1.is_urgent_switch = 1)
                AND NOT (
                    -- 排除：订单状态为50（取消）且取消时间在夜间（21点-9点）
                    t2.order_status = 50
                    AND t2.cancel_time IS NOT NULL 
                    AND (
                        HOUR(t2.cancel_time) >= 21  -- 当天21点之后
                        OR HOUR(t2.cancel_time) < 9  -- 或第二天9点之前
                    )
                )
            THEN t1.order_no  
        END AS `总订单_新口径`,
        
        CASE 
            WHEN t1.is_2_hour_urgent_on_door = 1 
                AND (t1.is_urgent_order = 1 OR t1.is_urgent_switch = 1)
                AND NOT (
                    -- 排除：订单状态为50（取消）且取消时间在夜间（21点-9点）
                    t2.order_status = 50
                    AND t2.cancel_time IS NOT NULL 
                    AND (
                        HOUR(t2.cancel_time) >= 21  -- 当天21点之后
                        OR HOUR(t2.cancel_time) < 9  -- 或第二天9点之前
                    )
                )
            THEN t1.order_no 
        END AS `2h上门_新口径`
        
    FROM rpt.rpt_jiafu_urgent_order_info_da t1
    -- 关联订单表获取取消时间和订单状态
    LEFT JOIN olap.olap_hj_fas_main_order_service_info_da t2
        ON t1.order_no = t2.order_no
        AND t2.pt = '20260111000000'
    WHERE t1.pt = '20260111000000'
        AND SUBSTR(t1.order_create_time, 1, 7) >= '2025-06'  -- 筛选2025年6月及之后的数据
        AND SUBSTR(t1.order_create_time, 1, 7) <= '2025-12'  -- 筛选2025年12月及之前的数据
        AND (t1.urgent_flag IN (1, 2) OR t1.performance_mode IN (1, 2))
) kk 
    ON kk.city_name = numbers.city_name
WHERE numbers.month_string >= '2025-06'  -- 查询6月到12月
    AND numbers.month_string <= '2025-12'
GROUP BY 
    numbers.city_name,
    SUBSTR(numbers.month_string, 1, 7)
ORDER BY 
    SUBSTR(numbers.month_string, 1, 7),
    numbers.city_name