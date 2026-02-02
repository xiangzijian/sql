-- 西安市2025年11月租期维修单关联咨询工单明细
-- 用于核对数据

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
        question_desc,
        appeal_tag_cn,
        real_deal_name,
        close_time
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
        AND city_name = '西安市'  -- 限定西安市
        AND ctime >= '2025-01-01 00:00:00'
        AND ctime < '2027-01-01 00:00:00'
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
        bizcircle_name,
        service_order_complete_time,
        order_complete_time,
        user_evaluation_star,
        user_evaluation_remark,
        order_creator_name,
        contact_user_mobile,
        cancel_reason
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${pt_date}'  -- 替换为实际分区日期
        AND service_code = '10003'  -- 维修品类
        AND order_type = '16'  -- 轻托管维修单（租期维修单）
        AND lease_status IN ('2', '3')  -- 未入住或已出租
        AND city_name = '西安市'  -- 限定西安市
        AND order_create_time >= '2025-11-01 00:00:00'  -- 2025年11月
        AND order_create_time < '2025-12-01 00:00:00'   -- 11月底
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

-- Step4: 获取商品明细
commodity_data AS (
    SELECT
        order_no,
        CONCAT_WS(',', COLLECT_LIST(commodity_name)) AS commodity_list
    FROM olap.olap_hj_fas_main_order_commodity_da
    WHERE pt = '${pt_date}'
        AND commodity_type = 1  -- 主商品
    GROUP BY order_no
),

-- Step5: 通过中间表关联维修单号和咨询工单
relation_data AS (
    SELECT DISTINCT
        ticket_id,
        repair_order
    FROM ods.ods_plat_private_domain_ticket_repair_order_relation_da
    WHERE pt = '${pt_date}'  -- 替换为实际分区日期
        AND repair_order IS NOT NULL
        AND ticket_id IS NOT NULL
),

-- Step6: 拆分多个维修单号（repair_order字段可能包含多个逗号分隔的单号）
relation_expanded AS (
    SELECT DISTINCT
        ticket_id,
        trim(repair_order_item) AS repair_order
    FROM relation_data
    LATERAL VIEW explode(split(repair_order, ',')) t AS repair_order_item
    WHERE trim(repair_order_item) != ''
),

-- Step7: 关联所有数据
joined_data AS (
    SELECT 
        SUBSTR(r.order_create_time, 1, 10) AS `创建日期`,
        r.order_no AS `维修单号`,
        r.order_create_time AS `维修单创建时间`,
        r.city_name AS `城市`,
        r.resblock_name AS `小区名称`,
        r.bizcircle_name AS `商圈名称`,
        c.commodity_list AS `商品名称`,
        r.service_order_supplier_name AS `供应商`,
        r.service_order_professional_name AS `服务者`,
        r.order_creator_name AS `下单人`,
        r.contact_user_mobile AS `联系电话`,
        r.first_call_time AS `首次呼叫时间`,
        r.service_order_complete_time AS `完工时间`,
        r.order_complete_time AS `完单时间`,
        CASE 
            WHEN r.order_status = 50 THEN '已取消'
            WHEN r.order_status = 40 THEN '已完成'
            WHEN r.order_status = 30 THEN '待付款'
            WHEN r.order_status = 24 THEN '服务中'
            WHEN r.order_status = 23 THEN '待服务'
            ELSE CAST(r.order_status AS STRING)
        END AS `订单状态`,
        r.cancel_time AS `取消时间`,
        r.cancel_reason AS `取消原因`,
        r.user_evaluation_star AS `评价星级`,
        r.user_evaluation_remark AS `评价备注`,
        t.ticket_id AS `咨询工单ID`,
        t.ticket_create_time AS `咨询工单创建时间`,
        t.three_current_name AS `咨询三级分类`,
        t.appeal_tag_cn AS `工单诉求标签`,
        t.real_deal_name AS `实际处理人`,
        t.close_time AS `工单关闭时间`,
        t.question_desc AS `问题描述`,
        CASE 
            WHEN t.ticket_create_time < r.order_create_time THEN '咨询在维修前'
            ELSE '咨询在维修后'
        END AS `咨询与维修时序`,
        DATEDIFF(
            FROM_UNIXTIME(UNIX_TIMESTAMP(r.order_create_time, 'yyyy-MM-dd HH:mm:ss')),
            FROM_UNIXTIME(UNIX_TIMESTAMP(t.ticket_create_time, 'yyyy-MM-dd HH:mm:ss'))
        ) AS `维修单距离咨询天数`
    FROM repair_order_data r
    INNER JOIN relation_expanded re ON r.order_no = re.repair_order
    INNER JOIN ticket_data t ON t.ticket_id = re.ticket_id
    LEFT JOIN commodity_data c ON c.order_no = r.order_no
)

-- 输出明细数据
SELECT 
    `创建日期`,
    `维修单号`,
    `维修单创建时间`,
    `城市`,
    `小区名称`,
    `商圈名称`,
    `商品名称`,
    `供应商`,
    `服务者`,
    `下单人`,
    `联系电话`,
    `首次呼叫时间`,
    `完工时间`,
    `完单时间`,
    `订单状态`,
    `取消时间`,
    `取消原因`,
    `评价星级`,
    `评价备注`,
    `咨询工单ID`,
    `咨询工单创建时间`,
    `咨询三级分类`,
    `工单诉求标签`,
    `实际处理人`,
    `工单关闭时间`,
    `问题描述`,
    `咨询与维修时序`,
    `维修单距离咨询天数`
FROM joined_data
ORDER BY `创建日期`, `维修单创建时间`;

-- 汇总统计
/*
SELECT 
    '西安市2025年11月汇总' AS `统计说明`,
    COUNT(DISTINCT `维修单号`) AS `有咨询记录的维修单量`,
    COUNT(DISTINCT `咨询工单ID`) AS `关联的咨询工单数`,
    COUNT(DISTINCT `供应商`) AS `供应商数量`,
    COUNT(DISTINCT `服务者`) AS `服务者数量`,
    SUM(CASE WHEN `订单状态` = '已完成' THEN 1 ELSE 0 END) AS `已完成订单数`,
    SUM(CASE WHEN `订单状态` = '已取消' THEN 1 ELSE 0 END) AS `已取消订单数`,
    SUM(CASE WHEN `咨询与维修时序` = '咨询在维修前' THEN 1 ELSE 0 END) AS `咨询在前的单量`,
    SUM(CASE WHEN `咨询与维修时序` = '咨询在维修后' THEN 1 ELSE 0 END) AS `咨询在后的单量`
FROM joined_data;
*/
