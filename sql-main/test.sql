-- ==================== 新口径1小时首联量 - 明细订单号 ====================
-- 筛选条件：非紧急单，去掉1小时内取消订单+夜间取消单，排除紧急单

SELECT DISTINCT
    a.city_name AS `城市`,
    SUBSTR(a.order_create_time, 1, 7) AS `月份`,
    a.order_no AS `订单号`,
    a.order_create_time AS `订单创建时间`,
    a.first_call_time AS `首次致电时间`,
    a.cancel_time AS `取消时间`,
    a.order_status AS `订单状态`,
    a.label_group AS `标签组`,
    a.lease_status AS `租赁状态`,
    CASE 
        WHEN a.cancel_time = '1000-01-01 00:00:00' THEN '未取消'
        WHEN a.order_status = 50 THEN '已取消'
        ELSE '其他'
    END AS `取消状态说明`,
    CASE 
        WHEN a.is_not = 1 THEN '夜间单符合次日10点前致电'
        WHEN substr(a.first_call_time, 1, 4) >= '2000' 
            AND (unix_timestamp(a.first_call_time, 'yyyy-MM-dd HH:mm:ss')
                 - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60 
        THEN '1小时内首次致电'
        ELSE '其他'
    END AS `首联时效说明`,
    ROUND((unix_timestamp(a.first_call_time, 'yyyy-MM-dd HH:mm:ss')
         - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60, 2) AS `创建到首联分钟数`,
    CASE 
        WHEN a.cancel_time != '1000-01-01 00:00:00' 
        THEN ROUND((unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                  - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60, 2)
        ELSE NULL
    END AS `创建到取消分钟数`

FROM (
    SELECT DISTINCT
        a.order_no,
        a.order_create_time,
        a.service_order_complete_time,
        a.first_call_time,
        a.cancel_time,
        a.order_status,
        a.label_group,
        a.lease_status,
        CASE
            WHEN substr(a.order_create_time, 12, 2) >= '21'
               AND a.first_call_time < concat(date_add(to_date(a.order_create_time), 1), ' 10:00:00')
               AND substr(a.first_call_time, 1, 4) >= '2000'
            THEN 1
            WHEN substr(a.order_create_time, 12, 2) < '09'
               AND a.first_call_time < concat(to_date(a.order_create_time), ' 10:00:00')
               AND substr(a.first_call_time, 1, 4) >= '2000'
            THEN 1
            ELSE 0
        END AS is_not,
        a.city_name
    FROM olap.olap_hj_fas_main_order_service_info_da a
    INNER JOIN (
        SELECT DISTINCT order_no AS oth_orderno
        FROM rpt.rpt_fas_light_hosting_order_detail_da
        WHERE pt = '20260202000000'
        AND vison_type = '4.0'
        AND service_name IN ('维修','燃气')
        AND order_type = '16'
        AND label_group NOT IN ('8')
        AND commodity_name_list1 NOT IN (
            '夏季空调预检', 'SCM00300001672373', '漏水专项检修','消防器材', '定损', '漏水定损','火灾定损','其他定损', '京北漏水定损', '京南漏水定损','京北火灾定损', '京南火灾定损',
            '京北其他定损', '京南其他定损')
        AND supplier_name NOT IN (
            '上海兰宫建筑装饰有限公司',
            '上海尚礼实业有限公司',
            '上海苏皖贸易有限公司',
            '上海再旭保洁服务有限公司',
            '源和里仁家具海安有限公司',
            '匠云（北京）科技有限公司'
        )
    ) b ON b.oth_orderno = a.order_no
    WHERE a.pt = '20260202000000'
    AND a.order_type = 16
    AND a.label_group NOT IN ('8')
) a

-- 关联紧急单数据
LEFT JOIN (
    SELECT DISTINCT
        order_create_time,
        order_no as order_no_1,
        case when city_name = '北京市' then manager_corp_name else city_name end as city_name,
        CASE WHEN is_urgent_order = 1 OR is_urgent_switch = 1 THEN order_no END as `总订单`,
        case when is_30_min_urgent_call = 1 and (is_urgent_order = 1 OR is_urgent_switch = 1) then order_no END as `紧急30分钟致电单`
    FROM rpt.rpt_jiafu_urgent_order_info_da
    WHERE pt = '20260202000000'
    AND substr(order_create_time, 1, 7) >= '2025-01'
    AND (urgent_flag in (1, 2) or performance_mode in (1))
) kk ON kk.order_no_1 = a.order_no

WHERE 1=1
    -- 指定查询月份（可修改）
    AND SUBSTR(a.order_create_time, 1, 7) = '2025-11'
    -- 指定城市（可修改）
    AND a.city_name = '济南市'
    -- 以下是新口径1小时首联量的核心筛选条件
    AND a.label_group NOT IN ('1', '8','25')
    AND a.lease_status IN (2, 3)
    -- 排除紧急单（新口径：先判断是否是紧急单）
    AND kk.`总订单` IS NULL
    -- 排除晚上21点-次日早上9点取消的订单
    AND NOT (a.cancel_time != '1000-01-01 00:00:00'
            AND (
                (substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09')
            ))
    -- 分子条件：夜间单符合次日10点前致电 或 1小时内首联
    AND (
        a.is_not = 1
        OR (substr(a.first_call_time, 1, 4) >= '2000'
            AND (unix_timestamp(a.first_call_time, 'yyyy-MM-dd HH:mm:ss')
                 - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60)
    )
    -- 新口径：去掉1小时内取消订单
    AND (a.cancel_time = '1000-01-01 00:00:00'
        OR (a.order_status = 50
            AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 > 60))

ORDER BY a.order_create_time, a.order_no
