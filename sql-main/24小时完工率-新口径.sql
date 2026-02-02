--模板查询：24小时完工率-新口径测算
-- 24小时完工统计新口径：2025年11-12月所有城市
-- 计算逻辑：完工耗时 = 完工时间 - 预约服务开始时间(service_start_time) ≤ 24小时

WITH numbers AS (
    SELECT
        CONCAT(year_string, '-', LPAD(n, 2, '0')) AS month_string,
        city_name
    FROM
        (SELECT n, city_name, year_string
         FROM
           (SELECT stack(12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) AS n) t1
         LATERAL VIEW EXPLODE(
           ARRAY('上海市', '天津市', '成都市', '杭州市', '苏州市', '宁波市', '深圳市', '济南市', '广州市', '西安市', '武汉市', '南京市','北京市')
         ) t2 AS city_name
         LATERAL VIEW EXPLODE(
           ARRAY('2025')
         ) t3 AS year_string
        ) t
    WHERE CONCAT(year_string, '-', LPAD(n, 2, '0')) IN ('2025-11', '2025-12')  -- 只统计11月和12月
)

SELECT
    a.city_name AS `城市`,
    SUBSTR(numbers.month_string, 1, 7) AS `月份`,
    -- 24小时完工量（新口径）：完工时间 - service_start_time <= 24小时
    COUNT(DISTINCT CASE
        WHEN SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND a.service_order_complete_time IS NOT NULL
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND a.label_group NOT IN ('1', '8','25')
        AND a.lease_status IN (2, 3)
        AND a.service_start_time IS NOT NULL  -- service_start_time不能为空
        AND SUBSTR(a.service_start_time, 1, 4) NOT IN ('1990','2050','1000')  -- service_start_time有效性检查
        -- 核心计算：完工时间 - service_start_time <= 24小时
        AND (unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
             - unix_timestamp(a.service_start_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24
        THEN a.order_no
        ELSE NULL
    END) AS `24小时完工单数量`,

    -- 旧口径24小时完工量：完工时间 - 订单创建时间 <= 24小时
    COUNT(DISTINCT CASE
        WHEN SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND a.service_order_complete_time IS NOT NULL
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND a.label_group NOT IN ('1', '8','25')
        AND a.lease_status IN (2, 3)
        -- 旧口径计算：完工时间 - 订单创建时间 <= 24小时
        AND (unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
             - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24
        THEN a.order_no
        ELSE NULL
    END) AS `旧口径24小时完工单数量`,

    -- 总订单数量（分母）
    COUNT(DISTINCT CASE
        WHEN SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND a.label_group NOT IN ('1', '8','25')
        AND a.lease_status IN (2, 3)
        THEN a.order_no
        ELSE NULL
    END) AS `总订单数量`
FROM numbers
LEFT JOIN
   (SELECT DISTINCT
    a.manager_corp_name,
    a.order_no,
    a.order_create_time,
    a.service_order_complete_time,
    a.service_start_time,  -- 新增：预约服务开始时间
    a.service_order_supplier_name,
    a.service_order_professional_name,
    a.service_order_professional_ucid,
    a.lease_status,
    a.label_group,
    a.city_name
    FROM
    olap.olap_hj_fas_main_order_service_info_da a
    INNER JOIN (
        SELECT DISTINCT
            order_no AS oth_orderno
        FROM rpt.rpt_fas_light_hosting_order_detail_da
        WHERE pt = '20260110000000'
        AND vison_type = '4.0'
        AND service_name IN ('维修','燃气')
        AND order_type = '16'
        AND label_group NOT IN ('8')  -- 排除检修
        AND commodity_name_list1 != '漏水专项检修'  -- 漏水专项检修排除
        AND commodity_name_list1 NOT IN (
            '夏季空调预检',
            'SCM00300001672373',
            '漏水专项检修',
            '消防器材',
            '定损',
            '漏水定损',
            '火灾定损',
            '其他定损',
            '京北漏水定损',
            '京南漏水定损',
            '京北火灾定损',
            '京南火灾定损',
            '京北其他定损',
            '京南其他定损'
        )  -- 排除各种定损相关商品
        AND supplier_name NOT IN (
            '上海兰宫建筑装饰有限公司',
            '上海尚礼实业有限公司',
            '上海苏皖贸易有限公司',
            '上海再旭保洁服务有限公司',
            '源和里仁家具海安有限公司',
            '匠云（北京）科技有限公司'
        )  -- 排除特定供应商
    ) b ON b.oth_orderno = a.order_no
    WHERE a.pt = '20260110000000'
    AND a.order_type = 16
    AND a.label_group NOT IN ('8')
    ) AS a
     on numbers.city_name = a.city_name

WHERE numbers.month_string <= substr(current_date,1,7)  -- 只统计到当前月份

GROUP BY
    a.city_name,
    substr(numbers.month_string, 1, 7)

ORDER BY
    `城市`,
    `月份`