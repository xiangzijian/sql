-- 统计2025-2026年每月创建的租期维修单中有咨询记录的单量
-- 剔除无致电时间取消单（订单状态=50，first_call_time是1000开头，有取消时间）
-- 通过中间表关联咨询工单，筛选维修相关咨询且剔除特定三级分类

WITH 
-- Step1: 获取需要排除的订单（漏水、定损相关）
excluded_orders AS (
    SELECT DISTINCT order_no
    FROM olap.olap_hj_fas_main_order_commodity_da
    WHERE pt = '${pt_date}'
        AND (
            commodity_name IN (
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
            )
            OR commodity_name LIKE '%漏水%'
            OR commodity_name LIKE '%定损%'
        )
),

-- Step2: 获取咨询工单数据
ticket_data AS (
    SELECT 
        ticket_id,
        city_name,
        ctime AS ticket_create_time,
        three_current_name,
        parent_name,
        ticket_status,
        question_desc
    FROM rpt.rpt_trusteeship_private_fuwu_houseout_renter_da 
    WHERE pt = '${pt_date}'  -- 替换为实际分区日期，如 '20260116000000'
        AND parent_name = '维修'  -- 一级分类为维修
        AND ticket_status NOT IN (5, 6)  -- 排除无效单和重复单
        AND three_current_name NOT IN (
            '指定服务者',
            '取消维修订单',
            '表扬维修师傅',
            '维修下单',
            '下单流程咨询',
            '服务范围内收费'
        )  -- 剔除不相关的三级分类
        AND ctime >= '2025-01-01 00:00:00'  -- 2025年及以后
        AND ctime < '2027-01-01 00:00:00'   -- 2026年之前
),

-- Step3: 获取维修订单数据（剔除取消单中无致电时间的，并排除漏水定损）
repair_order_data AS (
    SELECT 
        order_no,
        order_create_time,
        city_name,
        first_call_time,
        cancel_time,
        order_status,
        service_order_professional_name,
        service_order_supplier_name,
        resblock_name,
        bizcircle_name
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${pt_date}'  -- 替换为实际分区日期
        AND service_code = '10003'  -- 维修品类
        AND order_type = '16'  -- 轻托管维修单（租期维修单）
        AND lease_status IN ('2', '3')  -- 未入住或已出租
        AND order_create_time >= '2025-01-01 00:00:00'  -- 2025年及以后
        AND order_create_time < '2027-01-01 00:00:00'  -- 2026年之前
        -- 剔除无致电时间的取消单
        AND NOT (
            order_status = 50  -- 订单取消
            AND (first_call_time IS NULL 
                 OR first_call_time LIKE '1000%'  -- 无效时间（1000开头）
                 OR first_call_time = '1000-01-01 00:00:00'
            )
            AND cancel_time IS NOT NULL  -- 有取消时间
        )
        -- 排除漏水、定损相关订单
        AND order_no NOT IN (SELECT order_no FROM excluded_orders)
),

-- Step4: 通过中间表关联维修单号和咨询工单
relation_data AS (
    SELECT DISTINCT
        ticket_id,
        repair_order
    FROM ods.ods_plat_private_domain_ticket_repair_order_relation_da
    WHERE pt = '${pt_date}'  -- 替换为实际分区日期
        AND repair_order IS NOT NULL
        AND ticket_id IS NOT NULL
),

-- Step5: 拆分多个维修单号（repair_order字段可能包含多个逗号分隔的单号）
relation_expanded AS (
    SELECT DISTINCT
        ticket_id,
        trim(repair_order_item) AS repair_order
    FROM relation_data
    LATERAL VIEW explode(split(repair_order, ',')) t AS repair_order_item
    WHERE trim(repair_order_item) != ''
),

-- Step6: 统计租后维修订单总量（参考健康度.sql逻辑，排除漏水定损）
total_repair_order AS (
    SELECT 
        SUBSTR(a.order_create_time, 1, 7) AS month,
        a.city_name,
        COUNT(DISTINCT a.order_no) AS total_repair_count
    FROM olap.olap_hj_fas_main_order_service_info_da a
    WHERE a.pt = '${pt_date}'
        AND a.order_type = '16'  -- 轻托管维修单
        AND a.label_group NOT IN ('1', '8', '25')  -- 排除检修、门锁、装配单
        AND a.lease_status IN ('2', '3')  -- 未入住或已出租（租后）
        AND a.order_create_time >= '2025-01-01 00:00:00'
        AND a.order_create_time < '2027-01-01 00:00:00'
        -- 排除漏水、定损相关订单
        AND a.order_no NOT IN (SELECT order_no FROM excluded_orders)
    GROUP BY SUBSTR(a.order_create_time, 1, 7), a.city_name
),

-- Step7: 关联维修单和咨询工单
joined_data AS (
    SELECT 
        SUBSTR(r.order_create_time, 1, 7) AS month,  -- 按月统计
        r.city_name,
        r.order_no,
        r.order_create_time,
        r.first_call_time,
        r.cancel_time,
        r.order_status,
        r.service_order_professional_name,
        r.service_order_supplier_name,
        r.resblock_name,
        r.bizcircle_name,
        t.ticket_id,
        t.ticket_create_time,
        t.three_current_name,
        t.question_desc
    FROM repair_order_data r
    INNER JOIN relation_expanded re ON r.order_no = re.repair_order
    INNER JOIN ticket_data t ON t.ticket_id = re.ticket_id
    -- 去掉时间先后顺序限制，只要有关联就统计
    -- WHERE t.ticket_create_time < r.order_create_time  
)

-- Step8: 按月、城市汇总统计
SELECT 
    COALESCE(j.month, t.month) AS `月份`,
    COALESCE(j.city_name, t.city_name) AS `城市`,
    COALESCE(t.total_repair_count, 0) AS `租后维修订单总量`,
    COUNT(DISTINCT j.order_no) AS `有咨询记录的维修单量`,
    COUNT(DISTINCT j.ticket_id) AS `关联的咨询工单数`,
    ROUND(COUNT(DISTINCT j.order_no) * 100.0 / COALESCE(t.total_repair_count, 1), 2) AS `咨询单占比(%)`,
    COUNT(DISTINCT j.service_order_supplier_name) AS `供应商数量`,
    COUNT(DISTINCT j.service_order_professional_name) AS `服务者数量`
FROM joined_data j
FULL OUTER JOIN total_repair_order t 
    ON j.month = t.month AND j.city_name = t.city_name
GROUP BY COALESCE(j.month, t.month), COALESCE(j.city_name, t.city_name), t.total_repair_count
ORDER BY `月份`, `城市`;

-- 明细数据查询（可选，用于核查）
/*
SELECT 
    month AS `月份`,
    city_name AS `城市`,
    order_no AS `维修单号`,
    order_create_time AS `维修单创建时间`,
    first_call_time AS `首次呼叫时间`,
    service_order_professional_name AS `服务者`,
    service_order_supplier_name AS `供应商`,
    resblock_name AS `小区名称`,
    bizcircle_name AS `商圈名称`,
    ticket_id AS `咨询工单ID`,
    ticket_create_time AS `咨询工单创建时间`,
    three_current_name AS `咨询三级分类`,
    question_desc AS `问题描述`,
    order_status AS `订单状态`,
    cancel_time AS `取消时间`
FROM joined_data
ORDER BY month, city_name, order_create_time;
*/
