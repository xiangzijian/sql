--模板查询：26年健康度汇总统计
-- 统计范围：全部城市，2025年11月至2026年1月
-- 注意：当前使用 pt='20260128000000' (最新分区)，通过订单创建时间筛选2025-11至2026-01数据
-- 分组维度：月度、城市、供应商、服务者、服务者ID
-- 统计指标：
-- 1. 普通单致电分子、普通单致电分母、紧急单致电分子、紧急单致电分母
-- 2. 普通单及时上门量、普通单总量、紧急单及时上门量、紧急单创建单量
-- 3. 检修及时完工分子、全量检修单、租后及时完工单、租后全量单
-- 4. 综合运力分子、综合运力分母、家电运力分子、家电运力分母
-- 5. 检修完工商品量（检修重复报修分母）、出租后商品量（检修重复报修分子）
-- 6. 返修分母-租后维修（租期重复报修分母）、返修分子-租后维修（租期重复报修分子）
-- 紧急单/普通单口径：按 performance_mode 区分，0=普通单，1和2=紧急单

-- 获取首次修改服务时间的记录（从操作历史表，仅客户发起的改约）
WITH first_service_change AS (
    SELECT 
        service_order_code,
        get_json_object(remark, '$.changedServiceEnd') AS changed_service_end,
        operate_time AS first_change_time,
        ROW_NUMBER() OVER (PARTITION BY service_order_code ORDER BY operate_time ASC) AS rn
    FROM dw.dw_fas_jiafu_dispatch_service_order_operate_history_da
    WHERE pt = '20260128000000'
        AND operate_type_name = '修改服务时间'
        AND operator_role = 5  -- 仅客户发起的改约
),

-- 公共筛选条件：租后订单筛选（避免重复代码）
filtered_orders AS (
    SELECT DISTINCT order_no AS oth_orderno
    FROM rpt.rpt_fas_light_hosting_order_detail_da
    WHERE pt = '20260128000000'
        AND vison_type = '4.0'
        AND service_name IN ('维修','燃气')
        AND order_type = '16'
        AND label_group NOT IN ('1', '8','25')
        AND commodity_name_list1 != '漏水专项检修'
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
        )
        AND supplier_name NOT IN (
            '上海兰宫建筑装饰有限公司',
            '上海尚礼实业有限公司',
            '上海苏皖贸易有限公司',
            '上海再旭保洁服务有限公司',
            '源和里仁家具海安有限公司',
            '匠云（北京）科技有限公司'
        )
),

-- 检修订单筛选：排除特定商品和供应商（参考检修出租前完工率逻辑）
filtered_inspection_orders AS (
    SELECT DISTINCT order_no AS oth_orderno
    FROM rpt.rpt_fas_light_hosting_order_detail_da
    WHERE pt = '20260128000000'
        AND vison_type = '4.0'
        AND service_name IN ('维修', '燃气')
        AND order_type = '16'
        AND label_group NOT IN ('8')  -- 检修单不排除1和25
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
        )
        AND supplier_name NOT IN (
            '上海兰宫建筑装饰有限公司',
            '上海尚礼实业有限公司',
            '上海苏皖贸易有限公司',
            '上海再旭保洁服务有限公司',
            '源和里仁家具海安有限公司',
            '匠云（北京）科技有限公司'
        )
),

-- 获取房源的出租记录（起租日期）
house_lease_info AS (
    SELECT DISTINCT
        house_code,
        effective_start_date AS lease_start_date  -- 合同起租日
    FROM rpt.rpt_plat_manager_workbench_manager_task_da
    WHERE pt = '20260128000000'
        AND effective_start_date IS NOT NULL
        AND effective_start_date != '1000-01-01 00:00:00'
        AND SUBSTR(effective_start_date, 1, 4) >= '2000'
),

-- 获取房源在特定时间段内的起租记录（用于检修及时完工判断：49小时-7天内无出租）
-- 注意：为避免笛卡尔积，每个房源只保留最早的起租记录
house_lease_info_period AS (
    SELECT 
        house_code,
        lease_start_date
    FROM (
        SELECT 
            house_code,
            lease_start_date,
            ROW_NUMBER() OVER (PARTITION BY house_code ORDER BY lease_start_date ASC) AS rn
        FROM house_lease_info
    ) t
    WHERE rn = 1
),

-- 获取运力数据：按订单维度聚合运力请求
capacity_data AS (
    SELECT 
        a.order_no,
        a.city_name,
        SUBSTR(a.order_create_time, 1, 7) AS order_month,
        -- 判断订单是否包含维修综合商品
        MAX(CASE 
            WHEN c.commodity_code IN (
                'CM00300000048611', 'CM00300000035381', 'CM00300000031856', 'CM00300000015322', 
                'CM00300000011582', 'CM00300001615920', 'CM00300000472146', 'CM00300000045028', 
                'CM00300000042537', 'CM00300000033348', 'CM00300000030730', 'CM00300000023281', 
                'CM00300000017957', 'CM00300000014849', 'CM00300000009439', 'CM00300002378666', 
                'CM00300000471848', 'CM00300002379296', 'CM00300000128429', 'CM00300000044135', 
                'CM00300000041205', 'CM00300000032923', 'CM00300000029123', 'CM00300000016932', 
                'CM00300000012090', 'CM00300000478370', 'CM00300001070862', 'CM00300000474070'
            ) THEN 1 ELSE 0 
        END) AS has_comprehensive,
        -- 判断订单是否包含维修家电商品
        MAX(CASE 
            WHEN c.commodity_code IN (
                'CM00300000480465', 'CM00300000043776', 'CM00300000028473', 'CM00300000018922', 
                'CM00300000224171', 'CM00300000019427', 'CM00300000006039'
            ) THEN 1 ELSE 0 
        END) AS has_appliance
    FROM olap.olap_hj_fas_main_order_service_info_da a
    LEFT JOIN olap.olap_hj_fas_main_order_commodity_da c
        ON a.order_no = c.order_no
        AND c.pt = '20260128000000'
        AND c.commodity_type = 1  -- 下单商品
    WHERE a.pt = '20260128000000'
        AND a.order_type = 16
        AND SUBSTR(a.order_create_time, 1, 7) IN ('2025-11', '2025-12', '2026-01')
    GROUP BY a.order_no, a.city_name, SUBSTR(a.order_create_time, 1, 7)
),

-- 获取运力请求数据：从运力调度日志表获取
capacity_request AS (
    SELECT 
        CAST(a.city_code AS STRING) AS city_code_str,
        a.city_name,
        SUBSTR(a.create_time, 1, 7) AS request_month,
        -- 生成唯一请求标识
        CONCAT(a.city_code, '_', a.biz_circle_id, '_', a.house_code, '_', a.operator_uc_id, '_', a.operate_source, '_', a.create_time) AS request_key,
        -- 判断是否2日内有运力
        CASE 
            WHEN a.valid = 1 
                AND (a.target_date = TO_DATE(a.create_time) 
                     OR a.target_date = DATE_ADD(TO_DATE(a.create_time), 1))
            THEN 1 
            ELSE 0 
        END AS has_capacity_2days,
        -- 判断商品类型
        CASE 
            WHEN a.commodity_code IN (
                'CM00300000048611', 'CM00300000035381', 'CM00300000031856', 'CM00300000015322', 
                'CM00300000011582', 'CM00300001615920', 'CM00300000472146', 'CM00300000045028', 
                'CM00300000042537', 'CM00300000033348', 'CM00300000030730', 'CM00300000023281', 
                'CM00300000017957', 'CM00300000014849', 'CM00300000009439', 'CM00300002378666', 
                'CM00300000471848', 'CM00300002379296', 'CM00300000128429', 'CM00300000044135', 
                'CM00300000041205', 'CM00300000032923', 'CM00300000029123', 'CM00300000016932', 
                'CM00300000012090', 'CM00300000478370', 'CM00300001070862', 'CM00300000474070'
            ) THEN '维修综合'
            WHEN a.commodity_code IN (
                'CM00300000480465', 'CM00300000043776', 'CM00300000028473', 'CM00300000018922', 
                'CM00300000224171', 'CM00300000019427', 'CM00300000006039'
            ) THEN '维修家电'
            ELSE '其他'
        END AS repair_type,
        CAST(a.house_code AS BIGINT) AS house_resource_id,
        a.create_time AS request_create_time
    FROM ods.ods_plat_jiafu_dispatch_capacity_dispatch_stream_log_ha a
    LEFT JOIN olap.olap_trusteeship_hdel_delivery_examine_task_da b
        ON a.house_code = b.trusteeship_housedel_code 
        AND b.pt = '20260128000000'
    WHERE a.pt = '20260128000000'
        AND a.need_check = 1
        AND b.manager_corp_name LIKE '%惠居%'
        AND a.valid != -1
        AND a.city_code != '666666'
        AND a.service_code = 10003
        AND a.create_time >= '2025-11-01'
        AND a.create_time < '2026-02-01'
        AND a.commodity_code IN (
            'CM00300000480465', 'CM00300000128429', 
            'CM00300000048611', 'CM00300000045028', 'CM00300000044135', 
            'CM00300000043776', 'CM00300000042537', 'CM00300000041205', 
            'CM00300000035381', 'CM00300000033348', 'CM00300000032923', 
            'CM00300000031856', 'CM00300000030730', 'CM00300000029123', 
            'CM00300000028473', 'CM00300000023281', 'CM00300000019427', 
            'CM00300000018922', 'CM00300000017957', 'CM00300000016932', 
            'CM00300000015322', 'CM00300000014849', 'CM00300000012090', 
            'CM00300000011582', 'CM00300000009439', 'CM00300000006039',  
            'CM00300000224171', 'CM00300002378666', 'CM00300000478370', 
            'CM00300001615920', 'CM00300000471848', 'CM00300001070862', 
            'CM00300000472146', 'CM00300002379296', 'CM00300000474070', 
            'CM00300000046464'
        )
),

-- 获取出房起租日数据（用于检修返修统计）
house_rental_info AS (
    SELECT DISTINCT
        order_code,
        city_name,
        rent_start_date
    FROM (
        SELECT DISTINCT
            order_code,
            city_name,
            SUBSTR(effect_start_date, 1, 10) AS rent_start_date,
            DENSE_RANK() OVER(PARTITION BY contract_code ORDER BY property_submit_time DESC) AS rn
        FROM olap.olap_trusteeship_hdel_examine_divide_da
        WHERE pt = '20260128000000'
            AND task_type <> 12
            AND effect_start_date IS NOT NULL
            AND effect_start_date != '1000-01-01 00:00:00'
            AND SUBSTR(effect_start_date, 1, 4) >= '2000'
    ) t
    WHERE rn = 1
),

-- 获取检修完工商品数据（检修重复报修分母）
-- 使用 filtered_inspection_orders 筛选检修单
repair_complete_commodity AS (
    SELECT DISTINCT
        a.order_no,
        a.service_order_code,
        a.house_resource_id,
        a.city_name,
        SUBSTR(a.service_order_complete_time, 1, 7) AS complete_month,
        a.service_order_supplier_name,
        a.service_order_professional_name,
        a.service_order_professional_ucid,
        -- 获取功能间和商品名称
        d.function_name,
        d.product_name,
        -- 生成唯一标识：订单号+功能间+商品名称
        CONCAT(a.order_no, '_', COALESCE(d.function_name, ''), '_', COALESCE(d.product_name, '')) AS commodity_key
    FROM olap.olap_hj_fas_main_order_service_info_da a
    INNER JOIN filtered_inspection_orders b ON b.oth_orderno = a.order_no  -- 改为检修订单筛选表
    -- 关联商品表获取功能间和商品名称
    LEFT JOIN rpt.rpt_fas_jiafu_dispatch_service_order_product_da d
        ON a.service_order_code = d.service_order_code
        AND d.pt = '20260128000000'
        AND d.function_name IS NOT NULL
        AND d.function_name != ''
        AND d.product_name NOT IN (
            '机械锁（入户门）', '夏季空调预检', 'SCM00300001672373', '漏水专项检修', 
            '消防器材', '定损', '漏水定损', '火灾定损', '其他定损', 
            '京北漏水定损', '京南漏水定损', '京北火灾定损', '京南火灾定损',
            '京北其他定损', '京南其他定损'
        )
    -- 关联商品映射表，排除安装类商品
    LEFT JOIN olap.olap_hj_fas_main_order_commodity_da sc
        ON a.order_no = sc.order_no
        AND sc.pt = '20260128000000'
        AND sc.commodity_type = 1  -- 下单商品
    WHERE a.pt = '20260128000000'
        AND a.order_type = 16
        -- 检修单条件（label_group IN ('1', '25') OR lease_status IN (-1, 1)）
        AND (a.label_group IN ('1', '25') OR a.lease_status IN (-1, 1))
        -- 完工时间有效
        AND a.service_order_complete_time IS NOT NULL
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        -- 排除安装类商品
        AND (NVL(sc.fault_list, '') NOT LIKE '%安装%' AND NVL(sc.fault_desc, '') NOT LIKE '%安装%')
        -- 限制商品范围（参考文件中的商品列表）
        AND sc.commodity_name RLIKE ('冰箱|电热水器|空调|燃气灶|燃气热水器/壁挂炉|洗衣机|油烟机|中央空调|窗帘|窗户|灯具|电线/插座|柜子|晾衣杆|淋浴房|淋浴器|楼梯|马桶|门|排风扇|墙面|天花板/吊顶|洗手池|浴霸')
),

-- 获取6项商品数据（用于租后返修统计）
rental_repair_product AS (
    SELECT DISTINCT
        service_order_code,
        product_name,
        product_code
    FROM dw.dw_fas_jiafu_dispatch_service_order_product_da
    WHERE pt = '20260128000000'
        AND product_name RLIKE ('马桶|空调|洗手池|洗衣机|燃气灶|淋浴器|空 调|燃 气 灶|马 桶')
),

-- 获取返修数据（用于租后返修统计）
rental_repair_info AS (
    SELECT
        n.`返修单号`,
        n.`关联单号`,
        n.`返修时间`,
        n.`返修商品`,
        n.`返修商品名称`
    FROM (
        SELECT
            r.order_code AS `返修单号`,
            r.relate_order_code AS `关联单号`,
            r.order_create_date AS `返修时间`,
            g.commodity_code AS `返修商品`,
            g.commodity_name AS `返修商品名称`,
            ROW_NUMBER() OVER(
                PARTITION BY r.relate_order_code, g.commodity_name
                ORDER BY r.order_create_date
            ) AS rn
        FROM (
            SELECT
                order_code,
                relate_order_code,
                order_create_date
            FROM rpt.rpt_plat_beijia_transaction_trade_order_relate_info_di
            WHERE pt BETWEEN '20250301000000' AND '20260128000000'
                AND relate_type = '1'
                AND del_status = '1'
        ) r
        JOIN (
            SELECT
                order_no,
                commodity_code,
                commodity_name
            FROM olap.olap_hj_fas_main_order_commodity_da
            WHERE pt = '20260128000000'
                AND commodity_type = 1
                AND commodity_name RLIKE ('马桶|空调|洗手池|洗衣机|燃气灶|淋浴器|空 调|燃 气 灶|马 桶')
                AND (NVL(fault_list, '') NOT LIKE '%安装%' AND NVL(fault_desc, '') NOT LIKE '%安装%')
        ) g ON g.order_no = r.order_code
    ) n
    WHERE n.rn = 1
),

-- ==================== 咨询相关CTE ====================
-- 排除漏水定损相关订单
excluded_orders AS (
    SELECT DISTINCT order_no
    FROM olap.olap_hj_fas_main_order_commodity_da
    WHERE pt = '20260128000000'
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

-- 获取咨询工单数据
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
    WHERE pt = '20260128000000'
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
        AND ctime >= '2025-11-01 00:00:00'  -- 2025年11月至2026年1月
        AND ctime < '2027-01-01 00:00:00'   -- 2027年之前
),

-- 通过中间表关联维修单号和咨询工单
relation_data AS (
    SELECT DISTINCT
        ticket_id,
        repair_order
    FROM ods.ods_plat_private_domain_ticket_repair_order_relation_da
    WHERE pt = '20260128000000'
        AND repair_order IS NOT NULL
        AND ticket_id IS NOT NULL
),

-- 拆分多个维修单号（repair_order字段可能包含多个逗号分隔的单号）
relation_expanded AS (
    SELECT DISTINCT
        ticket_id,
        trim(repair_order_item) AS repair_order
    FROM relation_data
    LATERAL VIEW explode(split(repair_order, ',')) t AS repair_order_item
    WHERE trim(repair_order_item) != ''
),

-- ==================== 资质覆盖相关CTE ====================
-- 获取员工技能信息（维修家电、维修综合）
staff_ability AS (
    SELECT DISTINCT
        staff_ucid,
        CASE WHEN ability_list LIKE '%维修家电%' THEN 1 ELSE 0 END AS `维修家电`,
        CASE WHEN ability_list LIKE '%维修综合%' THEN 1 ELSE 0 END AS `维修综合`
    FROM olap.olap_fas_mht_staff_detail_da
    WHERE pt = '20260128000000'
        AND status_code = 0
        AND is_delete = 0
        AND biz_line = 10003
        AND role_list = '维修员'
        AND staff_ucid IS NOT NULL
),

-- 获取员工资质信息（资质类型）
staff_qualification AS (
    SELECT 
        professional_ucid,
        CASE 
            WHEN certificate_type = '1' THEN '低压电工证'
            WHEN certificate_type = '2' THEN '高空作业证'
            WHEN certificate_type = '3' THEN '燃气具安装维修工'
            WHEN certificate_type = '4' THEN '贝壳认证培训证书'
            ELSE '其他资质'
        END AS `资质类型`
    FROM (
        SELECT 
            professional_ucid,
            certificate_type,
            ROW_NUMBER() OVER (
                PARTITION BY professional_ucid, certificate_type 
                ORDER BY update_time DESC
            ) AS rn
        FROM ods.ods_plat_busercenter_professional_qualification_approval_di
            WHERE pt BETWEEN '20251001000000' AND '20260128000000'
            AND is_delete = 0 
            AND approval_status = 2
    ) t
    WHERE t.rn = 1
),

-- 获取出租后再次下单的商品数据（检修重复报修分子）
rental_after_commodity AS (
    SELECT DISTINCT
        a.order_no,
        a.order_create_time,
        a.house_resource_id,
        a.city_name,
        SUBSTR(a.order_create_time, 1, 7) AS order_month,
        a.service_order_supplier_name,
        a.service_order_professional_name,
        a.service_order_professional_ucid,
        -- 从订单商品列表中解析功能间和商品名称
        regexp_extract(split(a.item, '\\|')[2], ':::(.*)', 1) AS function_room_name,
        sc.commodity_name AS commodity_name,
        -- 生成唯一标识：订单号+功能间+商品名称
        CONCAT(a.order_no, '_', regexp_extract(split(a.item, '\\|')[2], ':::(.*)', 1), '_', sc.commodity_name) AS commodity_key
    FROM (
        SELECT 
            house_resource_id,
            order_create_time,
            order_no,
            service_order_supplier_name,
            service_order_professional_name,
            service_order_professional_ucid,
            city_name,
            explode(split(order_commodity_list, '\\|\\|\\|')) AS item
        FROM olap.olap_hj_fas_main_order_service_info_da
        WHERE pt = '20260128000000'
            AND order_type = 16
            AND label_group NOT IN ('8','13','1','25')
            AND lease_status IN (2, 3)
            AND SUBSTR(order_create_time, 1, 7) IN ('2025-11', '2025-12', '2026-01')
    ) a
    LEFT JOIN olap.olap_hj_fas_main_order_commodity_da sc
        ON a.order_no = sc.order_no
        AND sc.pt = '20260128000000'
        AND sc.commodity_type = 1  -- 下单商品
    WHERE NVL(sc.fault_list, '') NOT LIKE '%安装%'
        AND NVL(sc.fault_desc, '') NOT LIKE '%安装%'
),

numbers AS (
    SELECT
        month_string,
        city_name
    FROM (
        SELECT '2025-11' AS month_string UNION ALL
        SELECT '2025-12' AS month_string UNION ALL
        SELECT '2026-01' AS month_string
    ) months
    CROSS JOIN (
        SELECT '上海市' AS city_name UNION ALL
        SELECT '天津市' AS city_name UNION ALL
        SELECT '成都市' AS city_name UNION ALL
        SELECT '杭州市' AS city_name UNION ALL
        SELECT '苏州市' AS city_name UNION ALL
        SELECT '宁波市' AS city_name UNION ALL
        SELECT '深圳市' AS city_name UNION ALL
        SELECT '济南市' AS city_name UNION ALL
        SELECT '广州市' AS city_name UNION ALL
        SELECT '西安市' AS city_name UNION ALL
        SELECT '武汉市' AS city_name UNION ALL
        SELECT '南京市' AS city_name UNION ALL
        SELECT '北京市' AS city_name
    ) cities
)

SELECT
    numbers.city_name AS `城市`,
    SUBSTR(numbers.month_string, 1, 7) AS `月份`,
    COALESCE(a.service_order_supplier_name, '待分配') AS `供应商`,
    COALESCE(a.service_order_professional_name, '') AS `服务者`,
    COALESCE(a.service_order_professional_ucid, '') AS `服务者ID`,
    COALESCE(a.bizcircle_name, '') AS `商圈`,

    -- ==================== 新口径 ====================

    -- 新口径：先判断是否是紧急单，非紧急单计算1小时首联率，紧急单计算30分钟致电率
    -- 非紧急单：排除下单1小时内取消的订单 + 夜间21点-次日早上9点取消的订单
    -- 紧急单：排除下单30分钟内取消的订单 + 夜间21点-次日早上9点取消的订单

    -- 1小时首联量 - 新口径 (非紧急单，去掉1小时内取消订单+夜间取消单，排除紧急单)
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND a.label_group NOT IN ('1', '8','25')
        AND a.lease_status IN (2, 3)
        -- 普通单：performance_mode=0（1和2=紧急单）
        AND (a.performance_mode IS NULL OR a.performance_mode = 0)
        -- 排除晚上21点-次日早上9点取消的订单
        AND NOT (a.cancel_time != '1000-01-01 00:00:00'
                AND (
                    (substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                    OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09')
                ))
        AND (
            a.is_not = 1
            OR (substr(a.first_call_time, 1, 4) >= '2000'
                AND (unix_timestamp(a.first_call_time, 'yyyy-MM-dd HH:mm:ss')
                     - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60)
        )
        -- 新口径：1小时首联分子分母都去掉1小时内取消订单，先判断订单状态=50是已取消，再确认取消时长是否在时效内
        AND (a.cancel_time = '1000-01-01 00:00:00'
            OR (a.order_status = 50
                AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                    - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 > 60))
        THEN a.order_no
    END) AS `普通单致电分子`,

    -- 1小时首联分母 - 新口径 (非紧急单，去掉1小时内取消订单+夜间取消单，排除紧急单)
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND a.label_group NOT IN ('1', '8','25')
        AND a.lease_status IN (2, 3)
        -- 普通单：performance_mode=0（1和2=紧急单）
        AND (a.performance_mode IS NULL OR a.performance_mode = 0)
        -- 排除晚上21点-次日早上9点取消的订单
        AND NOT (a.cancel_time != '1000-01-01 00:00:00'
                AND (
                    (substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                    OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09')
                ))
        -- 新口径：1小时首联分子分母都去掉1小时内取消订单，先判断订单状态=50是已取消，再确认取消时长是否在时效内
        AND (a.cancel_time = '1000-01-01 00:00:00'
            OR (a.order_status = 50
                AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                    - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 > 60))
        THEN a.order_no
    END) AS `普通单致电分母`,

    -- 紧急单30分钟致电率分子 - 新口径 (紧急单performance_mode in (1,2)，去掉30分钟内取消订单+夜间取消单+首次致电前取消)
    COUNT(DISTINCT CASE WHEN
        kk.order_create_time IS NOT NULL
        AND SUBSTR(numbers.month_string, 1, 7) = substr(kk.order_create_time, 1, 7)
        AND a.order_no IS NOT NULL
        AND a.performance_mode IN (1, 2)
        -- 排除晚上21点-次日早上9点取消的订单
        AND NOT (a.cancel_time != '1000-01-01 00:00:00'
                AND (
                    (substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                    OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09')
                ))
        -- 新口径：紧急单30分钟致电分子分母去掉30分钟内取消订单，先判断订单状态=50是已取消，再确认取消时长是否在时效内
        AND (a.cancel_time = '1000-01-01 00:00:00'
            OR (a.order_status = 50
                AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                    - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 > 30))
        -- 剔除首次致电前取消的订单（和普通单逻辑一致）
        AND NOT (
            a.order_status = 50 
            AND a.cancel_time != '1000-01-01 00:00:00'
            AND (
                -- 情况1：没有致电时间（首次致电前取消）
                (a.first_call_time IS NULL 
                 OR a.first_call_time = '1000-01-01 00:00:00' 
                 OR SUBSTR(a.first_call_time, 1, 4) < '2000')
                OR
                -- 情况2：有致电时间，但取消时间在致电时间之前（首次致电前取消）
                (SUBSTR(a.first_call_time, 1, 4) >= '2000'
                 AND a.cancel_time < a.first_call_time)
            )
        )
        AND kk.`紧急30分钟致电单` IS NOT NULL
        THEN a.order_no
    END) AS `紧急单致电分子`,

    -- 紧急单致电分母 - 新口径 (紧急单performance_mode in (1,2)，去掉30分钟内取消订单+夜间取消单+首次致电前取消)
    COUNT(DISTINCT CASE WHEN
        kk.order_create_time IS NOT NULL
        AND SUBSTR(numbers.month_string, 1, 7) = substr(kk.order_create_time, 1, 7)
        AND a.order_no IS NOT NULL
        AND a.performance_mode IN (1, 2)
        -- 排除晚上21点-次日早上9点取消的订单
        AND NOT (a.cancel_time != '1000-01-01 00:00:00'
                AND (
                    (substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                    OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09')
                ))
        -- 新口径：紧急单30分钟致电分子分母去掉30分钟内取消订单，先判断订单状态=50是已取消，再确认取消时长是否在时效内
        AND (a.cancel_time = '1000-01-01 00:00:00'
            OR (a.order_status = 50
                AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                    - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 > 30))
        -- 剔除首次致电前取消的订单（和普通单逻辑一致）
        AND NOT (
            a.order_status = 50 
            AND a.cancel_time != '1000-01-01 00:00:00'
            AND (
                -- 情况1：没有致电时间（首次致电前取消）
                (a.first_call_time IS NULL 
                 OR a.first_call_time = '1000-01-01 00:00:00' 
                 OR SUBSTR(a.first_call_time, 1, 4) < '2000')
                OR
                -- 情况2：有致电时间，但取消时间在致电时间之前（首次致电前取消）
                (SUBSTR(a.first_call_time, 1, 4) >= '2000'
                 AND a.cancel_time < a.first_call_time)
            )
        )
        AND kk.`总订单` IS NOT NULL
        THEN a.order_no
    END) AS `紧急单致电分母`,

    -- ==================== 及时上门指标 ====================

    -- 普通单及时上门量（分子）：首次签到时间<=客户下单首次预约结束时间或未致电客户改约时间
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND a.label_group NOT IN ('1', '8','25')
        AND a.lease_status IN (2, 3)
        -- 普通单：performance_mode=0
        AND (a.performance_mode IS NULL OR a.performance_mode = 0)
        -- 首次签到时间存在且有效
        AND a.first_sign_time IS NOT NULL 
        AND a.first_sign_time != '1000-01-01 00:00:00'
        AND (
            -- 情况1：首次签到时间小于等于预约服务结束时间
            (a.service_end_time IS NOT NULL
             AND a.first_sign_time <= a.service_end_time)
            OR
            -- 情况2：未致电情况下客户改约，首次签到时间小于等于客户首次改约的服务结束时间
            ((a.first_call_time IS NULL 
              OR a.first_call_time = '1000-01-01 00:00:00'
              OR SUBSTR(a.first_call_time, 1, 4) < '2000')
             AND cst.changed_service_end IS NOT NULL
             AND a.first_sign_time <= cst.changed_service_end)
        )
        THEN a.order_no
    END) AS `普通单及时上门量`,

    -- 普通单总量（分母）：租后的创建订单量（首次致电前取消剔除）
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND a.label_group NOT IN ('1', '8','25')
        AND a.lease_status IN (2, 3)
        -- 普通单：performance_mode=0
        AND (a.performance_mode IS NULL OR a.performance_mode = 0)
        -- 剔除首次致电前取消的订单（非紧急单剔除条件：去除首次致电前取消的订单）
        AND NOT (
            a.order_status = 50 
            AND a.cancel_time != '1000-01-01 00:00:00'
            AND (
                -- 情况1：没有致电时间（首次致电前取消）
                (a.first_call_time IS NULL 
                 OR a.first_call_time = '1000-01-01 00:00:00' 
                 OR SUBSTR(a.first_call_time, 1, 4) < '2000')
                OR
                -- 情况2：有致电时间，但取消时间在致电时间之前（首次致电前取消）
                (SUBSTR(a.first_call_time, 1, 4) >= '2000'
                 AND a.cancel_time < a.first_call_time)
            )
        )
        THEN a.order_no
    END) AS `普通单总量`,

    -- 紧急单及时上门量（分子）：紧急单上门签到时间-创建时间<=2h
    COUNT(DISTINCT CASE WHEN
        kk.order_create_time IS NOT NULL
        AND SUBSTR(numbers.month_string, 1, 7) = substr(kk.order_create_time, 1, 7)
        AND a.order_no IS NOT NULL
        -- 紧急单：performance_mode in (1, 2)
        AND a.performance_mode IN (1, 2)
        -- 首次签到时间存在且有效
        AND a.first_sign_time IS NOT NULL
        AND a.first_sign_time != '1000-01-01 00:00:00'
        -- 紧急单2小时内上门
        AND (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
             - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 120
        -- 剔除首次致电前取消的订单（和普通单逻辑一致）
        AND NOT (
            a.order_status = 50 
            AND a.cancel_time != '1000-01-01 00:00:00'
            AND (
                -- 情况1：没有致电时间（首次致电前取消）
                (a.first_call_time IS NULL 
                 OR a.first_call_time = '1000-01-01 00:00:00' 
                 OR SUBSTR(a.first_call_time, 1, 4) < '2000')
                OR
                -- 情况2：有致电时间，但取消时间在致电时间之前（首次致电前取消）
                (SUBSTR(a.first_call_time, 1, 4) >= '2000'
                 AND a.cancel_time < a.first_call_time)
            )
        )
        THEN a.order_no
    END) AS `紧急单及时上门量`,

    -- 紧急单创建单量（分母）：租后创建紧急单量（剔除夜间取消单，首次致电前取消单剔除）
    COUNT(DISTINCT CASE WHEN
        kk.order_create_time IS NOT NULL
        AND SUBSTR(numbers.month_string, 1, 7) = substr(kk.order_create_time, 1, 7)
        AND a.order_no IS NOT NULL
        -- 紧急单：performance_mode in (1, 2)
        AND a.performance_mode IN (1, 2)
        -- 剔除夜间（21点到第二天9点）取消的订单
        AND NOT (
            a.order_status = 50
            AND a.cancel_time IS NOT NULL
            AND a.cancel_time != '1000-01-01 00:00:00'
            AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
            AND (
                CAST(SUBSTR(a.cancel_time, 12, 2) AS INT) >= 21  -- 晚上21点之后
                OR CAST(SUBSTR(a.cancel_time, 12, 2) AS INT) < 9  -- 早上9点之前
            )
        )
        -- 剔除首次致电前取消的订单（和普通单逻辑一致）
        AND NOT (
            a.order_status = 50 
            AND a.cancel_time != '1000-01-01 00:00:00'
            AND (
                -- 情况1：没有致电时间（首次致电前取消）
                (a.first_call_time IS NULL 
                 OR a.first_call_time = '1000-01-01 00:00:00' 
                 OR SUBSTR(a.first_call_time, 1, 4) < '2000')
                OR
                -- 情况2：有致电时间，但取消时间在致电时间之前（首次致电前取消）
                (SUBSTR(a.first_call_time, 1, 4) >= '2000'
                 AND a.cancel_time < a.first_call_time)
            )
        )
        THEN a.order_no
    END) AS `紧急单创建单量`,

    -- ==================== 及时完工指标 ====================

    -- 检修及时完工分子：检修完工时间在下单时间48h内 或 检修完工时间在下单时间49小时-7天内且该时间段内房源无出租的订单
    -- 参考：检修出租前完工率_按城市按月.sql 逻辑
    COUNT(DISTINCT CASE WHEN
        insp.order_month = numbers.month_string  -- 使用检修订单数据源
        -- 完工时间存在且有效
        AND insp.service_order_complete_time IS NOT NULL
        AND SUBSTR(insp.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        AND (
            -- 情况1：48小时内完工
            (unix_timestamp(insp.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
             - unix_timestamp(insp.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 48
            OR
            -- 情况2：49小时-7天内完工且期间无出租
            ((unix_timestamp(insp.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
              - unix_timestamp(insp.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 > 48
             AND (unix_timestamp(insp.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
                  - unix_timestamp(insp.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 168  -- 7天=168小时
             -- 检查在下单后49小时到完工期间，是否有起租记录（无起租记录则符合条件）
             -- 通过LEFT JOIN判断：如果h_check_period_insp.house_code IS NULL，说明该时间段内无起租记录
             AND h_check_period_insp.house_code IS NULL)
        )
        THEN insp.order_no
    END) AS `检修及时完工分子`,

    -- 全量检修单：所有检修单（分母），排除特定商品和供应商
    -- 参考：检修出租前完工率_按城市按月.sql 逻辑
    COUNT(DISTINCT CASE WHEN
        insp.order_month = numbers.month_string  -- 使用检修订单数据源
        THEN insp.order_no
    END) AS `全量检修单`,

    -- 租后及时完工单：完工时间-首次签到时间/客户首次预约时间<=24h（包含紧急单）
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        -- 租后单条件
        AND a.label_group NOT IN ('1', '8','25')
        AND a.lease_status IN (2, 3)
        -- 完工时间存在且有效
        AND a.service_order_complete_time IS NOT NULL
        AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
        -- 计算起始时间：首次签到时间<=首次预约服务时间，则用签到时间；否则用首次预约服务时间
        AND (
            -- 情况1：首次签到时间存在且<=首次预约服务时间，用签到时间
            (a.first_sign_time IS NOT NULL 
             AND a.first_sign_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.first_sign_time, 1, 4) >= '2000'
             AND a.service_start_time IS NOT NULL
             AND SUBSTR(a.service_start_time, 1, 4) >= '2000'
             AND a.first_sign_time <= a.service_start_time
             AND (unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
                  - unix_timestamp(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24)
            OR
            -- 情况2：首次签到时间>首次预约服务时间（迟到/爽约），用首次预约服务时间
            (a.first_sign_time IS NOT NULL 
             AND a.first_sign_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.first_sign_time, 1, 4) >= '2000'
             AND a.service_start_time IS NOT NULL
             AND SUBSTR(a.service_start_time, 1, 4) >= '2000'
             AND a.first_sign_time > a.service_start_time
             AND (unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
                  - unix_timestamp(a.service_start_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24)
            OR
            -- 情况3：没有签到时间，用首次预约服务时间
            ((a.first_sign_time IS NULL 
              OR a.first_sign_time = '1000-01-01 00:00:00'
              OR SUBSTR(a.first_sign_time, 1, 4) < '2000')
             AND a.service_start_time IS NOT NULL
             AND SUBSTR(a.service_start_time, 1, 4) >= '2000'
             AND (unix_timestamp(a.service_order_complete_time, 'yyyy-MM-dd HH:mm:ss')
                  - unix_timestamp(a.service_start_time, 'yyyy-MM-dd HH:mm:ss')) / 3600 <= 24)
        )
        THEN a.order_no
    END) AS `租后及时完工单`,

    -- 租后全量单：所有租后单（包含紧急单，分母，剔除检修、漏水、定损、致电前的取消）
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        -- 租后单条件
        AND a.label_group NOT IN ('1', '8','25')
        AND a.lease_status IN (2, 3)
        -- 剔除检修、漏水、定损（已通过label_group NOT IN ('1', '8','25')排除）
        -- 剔除首次致电前取消的订单
        AND NOT (
            a.order_status = 50 
            AND a.cancel_time != '1000-01-01 00:00:00'
            AND (
                -- 情况1：没有致电时间（首次致电前取消）
                (a.first_call_time IS NULL 
                 OR a.first_call_time = '1000-01-01 00:00:00' 
                 OR SUBSTR(a.first_call_time, 1, 4) < '2000')
                OR
                -- 情况2：有致电时间，但取消时间在致电时间之前（首次致电前取消）
                (SUBSTR(a.first_call_time, 1, 4) >= '2000'
                 AND a.cancel_time < a.first_call_time)
            )
        )
        THEN a.order_no
    END) AS `租后全量单`,

    -- ==================== 运力指标 ====================

    -- 综合运力分子：维修综合订单的2日内有运力的请求数
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND cap.has_comprehensive = 1
        AND cap_req.repair_type = '维修综合'
        AND cap_req.has_capacity_2days = 1
        THEN cap_req.request_key
    END) AS `综合运力分子`,

    -- 综合运力分母：维修综合订单的总请求数
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND cap.has_comprehensive = 1
        AND cap_req.repair_type = '维修综合'
        THEN cap_req.request_key
    END) AS `综合运力分母`,

    -- 家电运力分子：维修家电订单的2日内有运力的请求数
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND cap.has_appliance = 1
        AND cap_req.repair_type = '维修家电'
        AND cap_req.has_capacity_2days = 1
        THEN cap_req.request_key
    END) AS `家电运力分子`,

    -- 家电运力分母：维修家电订单的总请求数
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND cap.has_appliance = 1
        AND cap_req.repair_type = '维修家电'
        THEN cap_req.request_key
    END) AS `家电运力分母`,

    -- ==================== 检修返修指标 ====================

    -- 检修完工商品量（检修重复报修分母）：检修订单完工的商品量
    COUNT(DISTINCT CASE WHEN
        SUBSTR(repair_comp.complete_month, 1, 7) = numbers.month_string
        AND numbers.city_name = repair_comp.city_name
        AND COALESCE(insp.service_order_supplier_name, '待分配') = COALESCE(repair_comp.service_order_supplier_name, '待分配')
        AND COALESCE(insp.service_order_professional_name, '') = COALESCE(repair_comp.service_order_professional_name, '')
        AND COALESCE(insp.service_order_professional_ucid, '') = COALESCE(repair_comp.service_order_professional_ucid, '')
        -- 关联出房数据（通过order_code），确保是出房房源
        AND rent_info.order_code = repair_comp.order_no
        THEN repair_comp.commodity_key
    END) AS `检修完工商品量`,

    -- 出租后商品量（检修重复报修分子）：在出房起租后15天内，同一房源、同一功能间、同一商品再次下单的商品量
    COUNT(DISTINCT CASE WHEN
        SUBSTR(rental_after.order_month, 1, 7) = numbers.month_string
        AND numbers.city_name = rental_after.city_name
        AND COALESCE(insp.service_order_supplier_name, '待分配') = COALESCE(rental_after.service_order_supplier_name, '待分配')
        AND COALESCE(insp.service_order_professional_name, '') = COALESCE(rental_after.service_order_professional_name, '')
        AND COALESCE(insp.service_order_professional_ucid, '') = COALESCE(rental_after.service_order_professional_ucid, '')
        -- 关联检修完工商品和出房数据
        AND repair_comp.house_resource_id = rental_after.house_resource_id
        AND repair_comp.function_name = rental_after.function_room_name
        AND repair_comp.product_name = rental_after.commodity_name
        AND rent_info.order_code = repair_comp.order_no
        -- 订单时间在出房起租日后15天内
        AND rent_info.rent_start_date IS NOT NULL
        AND rental_after.order_create_time > rent_info.rent_start_date
        AND DATEDIFF(TO_DATE(rental_after.order_create_time), TO_DATE(rent_info.rent_start_date)) BETWEEN 0 AND 15
        THEN rental_after.commodity_key
    END) AS `出租后商品量`,

    -- ==================== 租后返修指标 ====================

    -- 返修分母-租后维修（租期重复报修分母）：上月完工的租后维修订单的商品量
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.service_order_complete_time, 1, 7) = DATE_FORMAT(
            ADD_MONTHS(TO_DATE(CONCAT(numbers.month_string, '-01')), -1),
            'yyyy-MM'
        )
        AND a.lease_status IN (2, 3)
        AND a.label_group NOT IN ('1', '8','25')
        -- 关联6项商品
        AND rental_prod.product_code IS NOT NULL
        THEN CONCAT(rental_prod.product_code, '-', a.order_no)
    END) AS `返修分母-租后维修`,

    -- 返修分子-租后维修（租期重复报修分子）：上月完工的租后维修订单中，后续出现返修的商品量
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.service_order_complete_time, 1, 7) = DATE_FORMAT(
            ADD_MONTHS(TO_DATE(CONCAT(numbers.month_string, '-01')), -1),
            'yyyy-MM'
        )
        AND a.lease_status IN (2, 3)
        AND a.label_group NOT IN ('1', '8','25')
        -- 关联6项商品
        AND rental_prod.product_code IS NOT NULL
        -- 关联返修数据
        AND repair_info.`返修单号` IS NOT NULL
        AND rental_prod.product_code = repair_info.`返修商品`
        THEN CONCAT(rental_prod.product_code, '-', a.order_no)
    END) AS `返修分子-租后维修`,

    -- ==================== 咨询相关指标 ====================

    -- 有咨询记录的维修单量：租后维修订单中，有咨询记录的订单数量
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND a.lease_status IN (2, 3)  -- 未入住或已出租（租后）
        AND a.label_group NOT IN ('1', '8','25')  -- 排除检修、门锁、装配单
        -- 排除漏水、定损相关订单
        AND excluded_orders_check.order_no IS NULL
        -- 关联咨询工单（通过relation_expanded和ticket_data关联）
        AND consult_relation.repair_order IS NOT NULL
        AND consult_ticket.ticket_id IS NOT NULL
        THEN a.order_no
    END) AS `有咨询记录的维修单量`,

    -- 租后维修订单总量：租后维修订单的总量（排除漏水定损）
    COUNT(DISTINCT CASE WHEN
        SUBSTR(a.order_create_time, 1, 7) = numbers.month_string
        AND a.lease_status IN (2, 3)  -- 未入住或已出租（租后）
        AND a.label_group NOT IN ('1', '8','25')  -- 排除检修、门锁、装配单
        -- 排除漏水、定损相关订单
        AND excluded_orders_check.order_no IS NULL
        THEN a.order_no
    END) AS `租后维修订单总量`,

    -- ==================== 资质覆盖指标 ====================

    -- 资质覆盖分母：家电有完工人数+综合有完工人数
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(a.service_order_complete_time, 1, 7) = numbers.month_string
            AND a.service_order_complete_time IS NOT NULL
            AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990', '2050', '1000')
            AND a.service_order_complete_time != '1000-01-01 00:00:00'
            AND staff_ability.`维修家电` = 1
        THEN a.service_order_professional_ucid
    END) +
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(a.service_order_complete_time, 1, 7) = numbers.month_string
            AND a.service_order_complete_time IS NOT NULL
            AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990', '2050', '1000')
            AND a.service_order_complete_time != '1000-01-01 00:00:00'
            AND staff_ability.`维修综合` = 1
        THEN a.service_order_professional_ucid
    END) AS `资质覆盖分母`,

    -- 资质覆盖分子：家电有资质人数+综合有资质人数
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(a.service_order_complete_time, 1, 7) = numbers.month_string
            AND a.service_order_complete_time IS NOT NULL
            AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990', '2050', '1000')
            AND a.service_order_complete_time != '1000-01-01 00:00:00'
            AND staff_ability.`维修家电` = 1
            AND staff_qual.`资质类型` = '高空作业证'
        THEN a.service_order_professional_ucid
    END) +
    COUNT(DISTINCT CASE 
        WHEN SUBSTR(a.service_order_complete_time, 1, 7) = numbers.month_string
            AND a.service_order_complete_time IS NOT NULL
            AND SUBSTR(a.service_order_complete_time, 1, 4) NOT IN ('1990', '2050', '1000')
            AND a.service_order_complete_time != '1000-01-01 00:00:00'
            AND staff_ability.`维修综合` = 1
            AND staff_qual.`资质类型` = '低压电工证'
        THEN a.service_order_professional_ucid
    END) AS `资质覆盖分子`

FROM numbers
-- 租后订单数据（用于租后相关指标）
LEFT JOIN (
    SELECT DISTINCT
        a.order_no,
        a.order_create_time,
        SUBSTR(a.order_create_time, 1, 7) AS order_month,  -- 订单月份，用于JOIN条件
        a.service_order_complete_time,
        a.first_call_time,
        a.first_sign_time,
        a.cancel_time,
        a.order_status,
        a.label_group,
        a.lease_status,
        a.service_order_supplier_name,
        a.service_order_professional_name,
        a.service_order_professional_ucid,
        a.service_order_code,
        a.service_end_time,
        a.service_start_time,
        a.service_start_time AS first_appointment_time,  -- 首次预约服务时间
        a.performance_mode,  -- 0=普通单，1和2=紧急单
        a.house_resource_id,
        a.bizcircle_name,  -- 商圈
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
    INNER JOIN filtered_orders b ON b.oth_orderno = a.order_no
    WHERE a.pt = '20260128000000'
    AND a.order_type = 16
    AND a.label_group NOT IN ('1', '8','25')
) a ON numbers.city_name = a.city_name 
      AND numbers.month_string = a.order_month  -- 关键：加上月份匹配条件，避免笛卡尔积

-- 检修订单数据（用于检修相关指标）
LEFT JOIN (
    SELECT DISTINCT
        a.order_no,
        a.order_create_time,
        SUBSTR(a.order_create_time, 1, 7) AS order_month,
        a.service_order_complete_time,
        a.label_group,
        a.lease_status,
        a.service_order_supplier_name,
        a.service_order_professional_name,
        a.service_order_professional_ucid,
        a.service_order_code,
        a.house_resource_id,
        a.bizcircle_name,
        a.city_name
    FROM olap.olap_hj_fas_main_order_service_info_da a
    INNER JOIN filtered_inspection_orders b ON b.oth_orderno = a.order_no
    WHERE a.pt = '20260128000000'
    AND a.order_type = 16
    AND (a.label_group IN ('1', '25') OR a.lease_status IN (-1, 1))
) insp ON numbers.city_name = insp.city_name 
         AND numbers.month_string = insp.order_month

-- 关联客户改约时间
LEFT JOIN (
    SELECT 
        service_order_code,
        changed_service_end
    FROM first_service_change
    WHERE rn = 1  -- 只取第一次修改记录
) cst ON cst.service_order_code = a.service_order_code

-- 关联房源起租信息（用于检修出租前完工率判断）
-- 为避免笛卡尔积，只关联最早的起租记录
LEFT JOIN (
    SELECT 
        house_code,
        lease_start_date
    FROM (
        SELECT 
            house_code,
            lease_start_date,
            ROW_NUMBER() OVER (PARTITION BY house_code ORDER BY lease_start_date ASC) AS rn
        FROM house_lease_info
    ) t
    WHERE rn = 1
) h 
    ON CAST(a.house_resource_id AS STRING) = h.house_code

-- 关联房源在特定时间段内的起租记录（用于租后订单，已移至检修订单专用）
-- 只关联在下单后49小时到完工期间有起租的记录
LEFT JOIN house_lease_info_period h_check_period_insp
    ON CAST(insp.house_resource_id AS STRING) = h_check_period_insp.house_code
    AND h_check_period_insp.lease_start_date >= FROM_UNIXTIME(UNIX_TIMESTAMP(TO_DATE(insp.order_create_time)) + 49 * 3600)
    AND h_check_period_insp.lease_start_date <= insp.service_order_complete_time

-- 关联订单商品信息（用于判断维修类型）
LEFT JOIN capacity_data cap
    ON a.order_no = cap.order_no
    AND numbers.city_name = cap.city_name
    AND SUBSTR(a.order_create_time, 1, 7) = cap.order_month

-- 关联运力请求数据（通过房源编码和时间范围关联）
-- 为避免笛卡尔积，每个房源+订单只取最近的一条运力请求记录
LEFT JOIN (
    SELECT 
        house_resource_id,
        city_name,
        request_month,
        request_create_time,
        repair_type,
        has_capacity_2days,
        request_key,  -- 运力请求唯一标识
        ROW_NUMBER() OVER (
            PARTITION BY house_resource_id, city_name, request_month 
            ORDER BY request_create_time DESC
        ) AS rn
    FROM capacity_request
) cap_req
    ON CAST(a.house_resource_id AS BIGINT) = cap_req.house_resource_id
    AND numbers.city_name = cap_req.city_name
    AND SUBSTR(a.order_create_time, 1, 7) = cap_req.request_month
    AND cap_req.rn = 1
    -- 运力请求时间在订单创建时间前后3天内
    AND ABS(DATEDIFF(TO_DATE(a.order_create_time), TO_DATE(cap_req.request_create_time))) <= 3

-- 关联出房起租日数据（用于检修返修统计）
LEFT JOIN house_rental_info rent_info
    ON insp.order_no = rent_info.order_code  -- 改为关联检修订单数据
    AND numbers.city_name = rent_info.city_name

-- 关联检修完工商品数据（检修重复报修分母）
LEFT JOIN repair_complete_commodity repair_comp
    ON insp.order_no = repair_comp.order_no  -- 改为关联检修订单数据
    AND numbers.city_name = repair_comp.city_name
    AND insp.order_month = repair_comp.complete_month
    AND COALESCE(insp.service_order_supplier_name, '待分配') = COALESCE(repair_comp.service_order_supplier_name, '待分配')
    AND COALESCE(insp.service_order_professional_name, '') = COALESCE(repair_comp.service_order_professional_name, '')
    AND COALESCE(insp.service_order_professional_ucid, '') = COALESCE(repair_comp.service_order_professional_ucid, '')

-- 关联出租后商品数据（检修重复报修分子）
LEFT JOIN rental_after_commodity rental_after
    ON repair_comp.house_resource_id = rental_after.house_resource_id
    AND repair_comp.function_name = rental_after.function_room_name
    AND repair_comp.product_name = rental_after.commodity_name
    AND numbers.city_name = rental_after.city_name
    AND insp.order_month = rental_after.order_month  -- 改为使用检修订单的月份
    AND COALESCE(insp.service_order_supplier_name, '待分配') = COALESCE(rental_after.service_order_supplier_name, '待分配')
    AND COALESCE(insp.service_order_professional_name, '') = COALESCE(rental_after.service_order_professional_name, '')
    AND COALESCE(insp.service_order_professional_ucid, '') = COALESCE(rental_after.service_order_professional_ucid, '')
    -- 订单时间在出房起租日后15天内
    AND rent_info.rent_start_date IS NOT NULL
    AND rental_after.order_create_time > rent_info.rent_start_date
    AND DATEDIFF(TO_DATE(rental_after.order_create_time), TO_DATE(rent_info.rent_start_date)) BETWEEN 0 AND 15

-- 关联6项商品数据（用于租后返修统计）
LEFT JOIN rental_repair_product rental_prod
    ON a.service_order_code = rental_prod.service_order_code

-- 关联返修数据（用于租后返修统计）
LEFT JOIN rental_repair_info repair_info
    ON a.order_no = repair_info.`关联单号`
    AND rental_prod.product_code = repair_info.`返修商品`

-- 关联咨询工单数据（用于咨询相关指标统计）
LEFT JOIN relation_expanded consult_relation
    ON a.order_no = consult_relation.repair_order
LEFT JOIN ticket_data consult_ticket
    ON consult_relation.ticket_id = consult_ticket.ticket_id
    AND numbers.city_name = consult_ticket.city_name

-- 关联排除订单表（用于排除漏水定损相关订单，避免在聚合函数中使用子查询）
LEFT JOIN excluded_orders excluded_orders_check
    ON a.order_no = excluded_orders_check.order_no

-- 关联员工技能信息（用于资质覆盖指标统计，仅用于租后订单）
LEFT JOIN staff_ability
    ON a.service_order_professional_ucid = staff_ability.staff_ucid

-- 关联员工资质信息（用于资质覆盖指标统计）
LEFT JOIN staff_qualification staff_qual
    ON a.service_order_professional_ucid = staff_qual.professional_ucid

-- 关联紧急单数据（仅 performance_mode in (1,2) 为紧急单，用于30分钟致电率）
LEFT JOIN (
    SELECT DISTINCT
        order_create_time,
        order_no as order_no_1,
        city_name,
        CASE WHEN is_urgent_order = 1 OR is_urgent_switch = 1 THEN order_no END as `总订单`,
        case when is_30_min_urgent_call = 1 and (is_urgent_order = 1 OR is_urgent_switch = 1) then order_no END as `紧急30分钟致电单`
    FROM rpt.rpt_jiafu_urgent_order_info_da
    WHERE pt = '20260128000000'
    AND substr(order_create_time, 1, 7) IN ('2025-11', '2025-12', '2026-01')
    AND performance_mode IN (1, 2)
) kk ON kk.order_no_1 = a.order_no
    AND kk.city_name = a.city_name

WHERE numbers.month_string <= SUBSTR(CAST(CURRENT_DATE() AS STRING), 1, 7)

GROUP BY 
    numbers.city_name, 
    SUBSTR(numbers.month_string, 1, 7),
    COALESCE(a.service_order_supplier_name, '待分配'),
    COALESCE(a.service_order_professional_name, ''),
    COALESCE(a.service_order_professional_ucid, ''),
    COALESCE(a.bizcircle_name, '')

ORDER BY `城市`, `月份`, `供应商`, `服务者`, `服务者ID`, `商圈`;
