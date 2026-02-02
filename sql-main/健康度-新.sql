WITH numbers AS (
    -- 你的日历表保持不变
    SELECT
        CONCAT(year_string, '-', LPAD(n, 2, '0')) AS month_string,
        city_name
    FROM
        (SELECT n, city_name, year_string
         FROM (SELECT stack(12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) AS n) t1  
         LATERAL VIEW EXPLODE(ARRAY('上海市', '天津市', '成都市', '杭州市', '苏州市', '宁波市', '深圳市', '济南市', '广州市', '西安市', '武汉市', '南京市','惠居京北','惠居京南')) t2 AS city_name
         LATERAL VIEW EXPLODE(ARRAY('2025', '2026')) t3 AS year_string
        ) t
),

-- 1. 先把 普通单(t2) 按商圈算好
t2_agg AS (
    SELECT 
        create_month, 
        city_name, 
        bizcircle_name, -- 必须在这里就带上商圈
        count(distinct case when `time_jishi` ='是' and performance_mode != '紧急单' then order_no end) as `普通上门分子`,
        count(distinct case when `cancel_call_time` ='否' and performance_mode != '紧急单' then order_no end) as `普通上门分母`
    FROM rpt.rpt_on_time_rate 
    WHERE pt='${-1d_pt}' AND order_category='其他'
    GROUP BY create_month, city_name, bizcircle_name
),

-- 2. 先把 紧急单(t3) 按商圈算好
t3_agg AS (
    SELECT 
        SUBSTR(service_end_time, 1, 7) as end_month, 
        city_name, 
        bizcircle_name, -- 必须在这里就带上商圈
        count(distinct case when performance_mode = 1 and `cancel_reason` != '夜间取消单' and `12time_2h` ='是' then order_no end) as `紧急上门分子`,
        count(distinct case when performance_mode = 1 and `cancel_reason` != '夜间取消单' then order_no end) as `紧急上门分母`
    FROM rpt.rpt_on_time_rate 
    WHERE pt='${-1d_pt}' AND order_category='其他'
    GROUP BY SUBSTR(service_end_time, 1, 7), city_name, bizcircle_name
)

-- 3. 最后合并，确保商圈对齐
SELECT 
    t1.month_string,
    t1.city_name,
    -- 核心：如果普通单没商圈，就取紧急单的商圈；反之亦然
    COALESCE(t2.bizcircle_name, t3.bizcircle_name) AS bizcircle_name,
    
    COALESCE(t2.`普通上门分子`, 0) AS `普通上门分子`,
    COALESCE(t2.`普通上门分母`, 0) AS `普通上门分母`,
    COALESCE(t3.`紧急上门分子`, 0) AS `紧急上门分子`,
    COALESCE(t3.`紧急上门分母`, 0) AS `紧急上门分母`

FROM numbers t1
-- 关联普通单
LEFT JOIN t2_agg t2 
    ON t1.month_string = t2.create_month 
    AND t1.city_name = t2.city_name

-- 关联紧急单 (注意：这里要用 FULL JOIN 或者特殊的关联逻辑来保全商圈)
-- 为了简单且不出错，这里建议用 FULL JOIN 连接 t2 和 t3 的商圈，
-- 但最稳妥的方式是再次 LEFT JOIN，并增加商圈条件：
FULL JOIN t3_agg t3 
    ON t1.month_string = t3.end_month 
    AND t1.city_name = t3.city_name 
    AND t2.bizcircle_name = t3.bizcircle_name -- 【关键】让同商圈的数据对齐

WHERE t1.month_string IS NOT NULL
-- 可选：过滤掉没有任何商圈数据的空行
AND COALESCE(t2.bizcircle_name, t3.bizcircle_name) IS NOT NULL;