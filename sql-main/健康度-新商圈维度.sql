WITH numbers AS (
    -- 你的日历表保持不变
    SELECT
        CONCAT(year_string, '-', LPAD(n, 2, '0')) AS month_string,
        city_name
    FROM
        (SELECT n, city_name, year_string
         FROM (SELECT stack(12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) AS n) t1  
         LATERAL VIEW EXPLODE(ARRAY('上海市', '天津市', '成都市', '杭州市', '苏州市', '宁波市', '深圳市', '济南市', '广州市', '西安市', '武汉市', '南京市','北京市')) t2 AS city_name
         LATERAL VIEW EXPLODE(ARRAY('2025', '2026')) t3 AS year_string
        ) t
),

-- 1. 按创建时间计算
t2_agg AS (
    SELECT 
        create_month, 
        city_name, 
        service_order_supplier_name,
        bizcircle_name,
        count(distinct case when performance_mode != '紧急单' and label_group12 ='租后维修' and order_category='其他' and cancel_1h= 0 and calltime_1h= '是' then order_no end) as `普通致电分子`,
        count(distinct case when performance_mode != '紧急单' and label_group12 ='租后维修' and order_category='其他' and cancel_1h= 0  then order_no end) as `普通致电分母`,
        count(distinct case when `call_time_30m`= '是' and performance_mode = '紧急单'  and order_category='其他' and cancel_30m= 0 then order_no end) as `紧急致电分子`,
        count(distinct case when performance_mode = '紧急单'  and order_category='其他' and cancel_30m= 0 then order_no end) as `紧急致电分母`,
        count(distinct case when performance_mode = '紧急单' and  label_group12 = '租后维修' and cancel_night = 0  and cancel_daytime = 0  and `urgent_is_sign_advance` ='是' then order_no end) as `紧急上门分子`,
        count(distinct case when performance_mode = '紧急单' and  label_group12 = '租后维修' and cancel_night = 0  and cancel_daytime = 0 then order_no end) as `紧急上门分母`,
        count(distinct case when label_group12 = '检修' examine_task_complete = 1 then order_no end) as `检修完工分子`,
        count(distinct case when label_group12 = '检修' then order_no end) as `检修完工分母`
    FROM rpt.rpt_on_time_rate 
    WHERE pt='20260201000000' 
    GROUP BY create_month, city_name, service_order_supplier_name,bizcircle_name
),

-- 2. 按预约结束时间计算
t3_agg AS (
    SELECT 
        SUBSTR(service_end_time, 1, 7) as end_month, 
        city_name, 
        service_order_supplier_name,
        bizcircle_name,
        count(distinct case when label_group12 = '租后维修' and `normal_is_sign_advance` ='是' and `cancel_call1` ='否'  and performance_mode != '紧急单'  then order_no end) as `普通上门分子`,
        count(distinct case when label_group12 = '租后维修' and `cancel_call1` ='否'  and performance_mode != '紧急单' then order_no end) as `普通上门分母`,
        count(distinct case when label_group12 = '租后维修' and order_category='其他' and `cancel_call1` ='否' andlease_task_complete = 1 and  then order_no end) as `租后完工分子`,
        count(distinct case when label_group12 = '租后维修' and order_category='其他' and `cancel_call1` ='否' then order_no end) as `租后完工分母`
    FROM rpt.rpt_on_time_rate 
    WHERE pt='20260201000000' 
    GROUP BY SUBSTR(service_end_time, 1, 7), city_name, service_order_supplier_name,bizcircle_name
),
 -- 3.运力满足
 t4_agg as (
    SELECT 
        month_y, 
        city_name, 
        supplier_name,
        biz_circle_name,
        sum(case when commodity_code='维修综合'  then  one_day else 0 end) as `当日运力满足综合分子`,
        sum(case when commodity_code='维修综合'  then  two_day else 0 end) as `2日内运力满足综合分子`,    
        sum(case when commodity_code='维修综合' then request else 0 end ) as `综合分母`,
        sum(case when commodity_code='维修家电'  then  one_day else 0 end) as `当日运力满足家电分子`,
        sum(case when commodity_code='维修家电'  then  two_day else 0 end) as `2日内运力满足家电分子`,    
        sum(case when commodity_code='维修家电' then request else 0 end ) as `家电分母`
        FROM rpt.rpt_delivery_capacity
        WHERE pt='20260201000000'
        GROUP BY month_y, city_name, supplier_name,biz_circle_name
 ),
t6_agg as (
    SELECT 
        month_string,
        city_name,
        service_order_supplier_name,
        bizcircle_name,
        count(distinct case when fenzi ='是' then CONCAT(product_code, '-', zu_order) end) as `租期返修分子`,
        count(distinct CONCAT(product_code, '-', zu_order)) as `租期返修分母`
    FROM rpt.rpt_zu_order_fanxiu 
    WHERE pt='20260201000000' 
    GROUP BY month_string, city_name, service_order_supplier_name,bizcircle_name
),
-- 6检修返修
 t7_agg as (
    SELECT 
        month_time,
        city,
        shang_2,
        shangq,
        count(distinct concat(id, room, shangp_1)) as `检修分母`,
        count(distinct case when order_2 is not null then concat(order_2, room_1, shangp_2) end  ) as `检修分子`
    FROM rpt.rpt_jianxiu_fanxiu 
    WHERE pt='20260201000000'   
    GROUP BY month_time, city, shang_2,shangq
)
SELECT 
    t1.month_string,
    t1.city_name,
    t2.service_order_supplier_name,
    t2.bizcircle_name,
    COALESCE(t2.`普通上门分子`, 0) AS `普通上门分子`,
    COALESCE(t2.`普通上门分母`, 0) AS `普通上门分母`,
    COALESCE(t2.`紧急上门分子`, 0) AS `紧急上门分子`,
    COALESCE(t2.`紧急上门分母`, 0) AS `紧急上门分母`,
    COALESCE(t3.`检修完工分子`, 0) AS `检修完工分子`,
    COALESCE(t3.`检修完工分母`, 0) AS `检修完工分母`,
    COALESCE(t3.`租后完工分子`, 0) AS `租后完工分子`,
    COALESCE(t3.`租后完工分母`, 0) AS `租后完工分母`,
    COALESCE(t2.`普通致电分子`, 0) AS `普通致电分子`,
    COALESCE(t2.`普通致电分母`, 0) AS `普通致电分母`,
    COALESCE(t2.`紧急致电分子`, 0) AS `紧急致电分子`,
    COALESCE(t2.`紧急致电分母`, 0) AS `紧急致电分母`,
    COALESCE(t4.`当日运力满足综合分子`, 0) AS `当日运力满足综合分子`,
    COALESCE(t4.`2日内运力满足综合分子`, 0) AS `2日内运力满足综合分子`,
    COALESCE(t4.`综合分母`, 0) AS `综合分母`,
    COALESCE(t4.`当日运力满足家电分子`, 0) AS `当日运力满足家电分子`,
    COALESCE(t4.`2日内运力满足家电分子`, 0) AS `2日内运力满足家电分子`,
    COALESCE(t4.`家电分母`, 0) AS `家电分母`,
    COALESCE(t6.`租期返修分子`, 0) AS `租期返修分子`,
    COALESCE(t6.`租期返修分母`, 0) AS `租期返修分母`,
    COALESCE(t7.`检修分母`, 0) AS `检修分母`,
    COALESCE(t7.`检修分子`, 0) AS `检修分子`
FROM numbers t1
-- 关联普通单
LEFT JOIN t2_agg t2 
    ON t1.month_string = t2.create_month 
    AND t1.city_name = t2.city_name
left JOIN t3_agg t3 
    ON t1.month_string = t3.end_month 
    AND t1.city_name = t3.city_name 
    AND t2.service_order_supplier_name = t3.service_order_supplier_name
    AND t2.bizcircle_name = t3.bizcircle_name
left JOIN t4_agg t4 
    ON t1.month_string = t4.month_y 
    AND t1.city_name = t4.city_name 
    AND t2.service_order_supplier_name = t4.supplier_name
    AND t2.bizcircle_name = t4.biz_circle_name
left JOIN t6_agg t6 
    ON t1.month_string = t6.month_string 
    AND t1.city_name = t6.city_name 
    AND t2.service_order_supplier_name = t6.service_order_supplier_name
    AND t2.bizcircle_name = t6.bizcircle_name
left JOIN t7_agg t7 
    ON t1.month_string = t7.month_time 
    AND t1.city_name = t7.city 
    AND t2.service_order_supplier_name = t7.shang_2
    AND t2.bizcircle_name = t7.shangq
WHERE t2.create_month IS NOT NULL

