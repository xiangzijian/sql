
-- 26健康度看板rpt_february_2026_maintenance_health_dashboard


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
        count(distinct case when performance_mode != '紧急单' and label_group12 ='租后维修' and order_category='其他' and cancel_1h= 0 and cancel_night = 0 and calltime_1h= '是' then order_no end) as `普通致电分子`,
        count(distinct case when performance_mode != '紧急单' and label_group12 ='租后维修' and order_category='其他' and cancel_1h= 0 and cancel_night = 0 then order_no end) as `普通致电分母`,
        count(distinct case when calltime_30m= '是' and performance_mode = '紧急单'  and order_category='其他' and cancel_30m= 0 and cancel_night = 0 then order_no end) as `紧急致电分子`,
        count(distinct case when performance_mode = '紧急单'  and order_category='其他' and cancel_30m= 0 and cancel_night = 0 then order_no end) as `紧急致电分母`,
        count(distinct case when performance_mode = '紧急单' and  label_group12 = '租后维修' and cancel_night = 0  and cancel_daytime = 0  and `urgent_is_sign_advance` ='是' then order_no end) as `紧急上门分子`,
        count(distinct case when performance_mode = '紧急单' and  label_group12 = '租后维修' and cancel_night = 0  and cancel_daytime = 0 then order_no end) as `紧急上门分母`,
        count(distinct case when label_group12 = '检修' and  examine_task_complete = 1 then order_no end) as `检修完工分子`,
        count(distinct case when label_group12 = '检修' then order_no end) as `检修完工分母`
    FROM rpt.rpt_on_time_rate 
    WHERE pt='${-1d_pt}' 
    GROUP BY create_month, city_name
),

-- 2. 按预约结束时间计算
t3_agg AS (
    SELECT 
        SUBSTR(service_end_time , 1, 7) as end_month, 
        city_name, 
        count(distinct case when label_group12 = '租后维修' and `normal_is_sign_advance` ='是' and `cancel_call1` ='否'  and performance_mode != '紧急单'  then order_no end) as `普通上门分子`,
        count(distinct case when label_group12 = '租后维修' and `cancel_call1` ='否'  and performance_mode != '紧急单' then order_no end) as `普通上门分母`,
        count(distinct case when label_group12 = '租后维修' and order_category='其他' and `cancel_call1` ='否' and lease_task_complete = 1  then order_no end) as `租后完工分子`,
        count(distinct case when label_group12 = '租后维修' and order_category='其他' and `cancel_call1` ='否' then order_no end) as `租后完工分母`
    FROM rpt.rpt_on_time_rate 
    WHERE pt='${-1d_pt}' 
    GROUP BY SUBSTR(service_end_time, 1, 7), city_name
),
 -- 3.运力满足
 t4_agg as (
    SELECT 
        month_y, 
        city_name,
        sum(case when commodity_code='维修综合'  then  one_day else 0 end) as `当日运力满足综合分子`,
        sum(case when commodity_code='维修综合'  then  two_day else 0 end) as `2日内运力满足综合分子`,    
        sum(case when commodity_code='维修综合' then request else 0 end ) as `综合分母`,
        sum(case when commodity_code='维修家电'  then  one_day else 0 end) as `当日运力满足家电分子`,
        sum(case when commodity_code='维修家电'  then  two_day else 0 end) as `2日内运力满足家电分子`,    
        sum(case when commodity_code='维修家电' then request else 0 end ) as `家电分母`
        from rpt.rpt_delivery_capacity
        WHERE pt='${-1d_pt}'
        GROUP BY month_y, city_name
 ),
-- 4.资质率 - 取每月最后一天的快照数据
t5_month_last_day AS (
    SELECT 
        date_format(month_start, 'yyyyMM') as month_key,
        CASE 
            WHEN date_format(month_start, 'yyyyMM') = date_format(current_date(), 'yyyyMM') 
            THEN concat(date_format(date_sub(current_date(), 1), 'yyyyMMdd'), '000000')
            ELSE concat(date_format(last_day(month_start), 'yyyyMMdd'), '000000')
        END as last_day_pt
    FROM (
        SELECT add_months('2026-01-01', pos) as month_start
        FROM (
            SELECT posexplode(split(space(CAST(months_between(current_date(), '2026-01-01') AS INT)), ' ')) as (pos, val)
        ) t_gen
    ) t_dates
),
t5_agg AS (
    SELECT 
        CONCAT(SUBSTR(a.pt, 1, 4), '-', SUBSTR(a.pt, 5, 2)) as month_pt, 
        a.city_name,
        sum(a.zonghezizhi_renshu) as `综合资质分子`,
        sum(a.zongherenshu) as `综合资质分母`,
        sum(a.jiadianzizhi_renshu) as `家电资质分子`,
        sum(a.jiadianrenshu) as `家电资质分母`
    FROM rpt.rpt_anquan_zizhi_chizheng_shanggang_hz a
    INNER JOIN t5_month_last_day b 
        ON a.pt = b.last_day_pt
    GROUP BY CONCAT(SUBSTR(a.pt, 1, 4), '-', SUBSTR(a.pt, 5, 2)), a.city_name
 ),
t6_agg as (
    SELECT 
        month_string,
        city_name,
        count(distinct case when fenzi ='是' then CONCAT(product_code, '-', zu_order) end) as `租期返修分子`,
        count(distinct CONCAT(product_code, '-', zu_order)) as `租期返修分母`
    FROM rpt.rpt_zu_order_fanxiu 
    WHERE pt='${-1d_pt}' 
    GROUP BY month_string, city_name
),
-- 6检修返修
 t7_agg as (
    SELECT 
        month_time,
        city,
        count(distinct concat(id, room, shangp_1)) as `检修分母`,
        count(distinct case when order_2 is not null then concat(order_2, room_1, shangp_2) end  ) as `检修分子`
    FROM rpt.rpt_jianxiu_fanxiu 
    WHERE pt='${-1d_pt}'   
    GROUP BY month_time, city
),
-- 咨询相关
 t8_agg as (
    select 
         month_string,
         city_name,
         sum(consultation_count) as `咨询工单数`,
         sum(house_kaohe_cnt) as `考核在管数`
    from rpt.rpt_wanjia_weixiu_inquiry_volume 
    WHERE pt='${-1d_pt}'   
    GROUP BY month_string, city_name
 )

insert overwrite table rpt.rpt_february_2026_maintenance_health_dashboard partition (pt='${-1d_pt}')

SELECT 
    t1.month_string,
    t1.city_name,
    t1.city_name,
    COALESCE(t3.`普通上门分子`, 0) AS `普通上门分子`,
    COALESCE(t3.`普通上门分母`, 0) AS `普通上门分母`,
    COALESCE(t2.`紧急上门分子`, 0) AS `紧急上门分子`,
    COALESCE(t2.`紧急上门分母`, 0) AS `紧急上门分母`,
    COALESCE(t2.`检修完工分子`, 0) AS `检修完工分子`,
    COALESCE(t2.`检修完工分母`, 0) AS `检修完工分母`,
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
    COALESCE(t5.`综合资质分子`, 0) AS `综合资质分子`,
    COALESCE(t5.`综合资质分母`, 0) AS `综合资质分母`,
    COALESCE(t5.`家电资质分子`, 0) AS `家电资质分子`,
    COALESCE(t5.`家电资质分母`, 0) AS `家电资质分母`,
    COALESCE(t6.`租期返修分子`, 0) AS `租期返修分子`,
    COALESCE(t6.`租期返修分母`, 0) AS `租期返修分母`,
    COALESCE(t7.`检修分母`, 0) AS `检修分母`,
    COALESCE(t7.`检修分子`, 0) AS `检修分子`,
    COALESCE(t8.`咨询工单数`, 0) AS `咨询工单数`,
    COALESCE(t8.`考核在管数`, 0) AS `考核在管数`
FROM numbers t1
-- 关联普通单
left JOIN t2_agg t2 
    ON t1.month_string = t2.create_month 
    AND t1.city_name = t2.city_name
left JOIN t3_agg t3 
    ON t1.month_string = t3.end_month 
    AND t1.city_name = t3.city_name 
left JOIN t4_agg t4 
    ON t1.month_string = t4.month_y 
    AND t1.city_name = t4.city_name 
left JOIN t5_agg t5 
    ON t1.month_string = t5.month_pt 
    AND t1.city_name = t5.city_name 
left JOIN t6_agg t6 
    ON t1.month_string = t6.month_string 
    AND t1.city_name = t6.city_name 
left JOIN t7_agg t7 
    ON t1.month_string = t7.month_time 
    AND t1.city_name = t7.city 
left JOIN t8_agg t8 
    ON t1.month_string = t8.month_string 
    AND t1.city_name = t8.city_name 

