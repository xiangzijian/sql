-- 全国维修订单商品明细（25年2月9日）
-- 包含服务者维修技能信息
-- 从order_commodity_list解析shelf_code，关联运力表获取commodity_code
SELECT 
    to_date(order_create_time) AS `日期`,
    order_no AS `订单号`,
    service_order_code AS `服务单号`,
    order_create_time AS `订单创建时间`,
    
    -- ========== 城市和供应商信息 ==========
    `城市`,
    `供应商`,
    supplier_name AS `员工所属供应商`,
    
    -- ========== 服务者信息 ==========
    service_order_professional_ucid AS `服务者UCID`,
    service_order_professional_name AS `服务者姓名`,
    ability_list AS `技能列表`,
    `技能类型`,
    
    -- ========== 商品信息 ==========
    `维修商品`,
    shelf_code AS `货架编码`,
    commodity_code AS `商品编码`,
    commodity_name AS `商品名称`,
    `维修类型`,
    
    -- ========== 订单分类信息 ==========
    label_group AS `标签组`,
    CASE 
        WHEN label_group IN ('1', '25') THEN '检修'
        WHEN label_group NOT IN ('1', '8', '25') AND lease_status IN (2, 3) THEN '租期维修'
        ELSE '其他'
    END AS `订单分类`,
    
    lease_status AS `租赁状态`,
    
    -- ========== 紧急程度 ==========
    performance_mode AS `履约模式`,
    CASE 
        WHEN performance_mode = 1 THEN '紧急单'
        WHEN performance_mode = 2 THEN '加急单'
        ELSE '普通单'
    END AS `紧急程度`
    
FROM (
    SELECT 
        a.order_no,
        a.order_create_time,
        a.service_order_professional_ucid,
        a.service_order_professional_name,
        a.label_group,
        a.lease_status,
        a.performance_mode,
        a.service_order_code,
        a.shelf_code,
        a.commodity_name,
        b.commodity_code,
        c.ability_list,
        c.supplier_name,
        -- 城市处理（区分京南京北）
        CASE 
            WHEN a.city_name = '北京市' AND a.manager_marketing_name IN ('京东事业部','京东南事业部','京东南租赁运营部','京东南运营','京东运营','京南事业部','京南大部','京南运营','京西南事业部','京西南运营') 
            THEN '惠居京南'
            WHEN a.city_name = '北京市' AND a.manager_marketing_name IN ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营') 
            THEN '惠居京北'
            ELSE a.city_name
        END AS `城市`,
        -- 供应商处理（部分城市需要映射）
        CASE 
            WHEN a.city_name IN ('广州市','深圳市','济南市') AND a.service_order_supplier_name = '上海翊帮人科技有限公司' 
            THEN '上海彼方建筑装饰工程有限公司'
            WHEN a.city_name = '深圳市' AND a.service_order_supplier_name = '云万服（广州）生活服务有限公司' 
            THEN '寰诚建筑（深圳）有限公司'
            ELSE a.service_order_supplier_name 
        END AS `供应商`,
        -- 维修商品（商品编码-商品名称）
        CONCAT(b.commodity_code, '-', a.commodity_name) AS `维修商品`,
        -- 判断维修类型（基于commodity_code）
        CASE 
            WHEN b.commodity_code IN (
                'CM00300000048611', 'CM00300000035381', 'CM00300000031856', 'CM00300000015322', 
                'CM00300000011582', 'CM00300001615920', 'CM00300000472146', 'CM00300000045028', 
                'CM00300000042537', 'CM00300000033348', 'CM00300000030730', 'CM00300000023281', 
                'CM00300000017957', 'CM00300000014849', 'CM00300000009439', 'CM00300002378666', 
                'CM00300000471848', 'CM00300002379296', 'CM00300000128429', 'CM00300000044135', 
                'CM00300000041205', 'CM00300000032923', 'CM00300000029123', 'CM00300000016932', 
                'CM00300000012090', 'CM00300000478370', 'CM00300001070862', 'CM00300000474070'
            ) THEN '维修综合'
            WHEN b.commodity_code IN (
                'CM00300000480465', 'CM00300000043776', 'CM00300000028473', 'CM00300000018922', 
                'CM00300000224171', 'CM00300000019427', 'CM00300000006039'
            ) THEN '维修家电'
            ELSE '其他'
        END AS `维修类型`,
        -- 判断技能类型（基于ability_list）
        CASE 
            WHEN c.ability_list LIKE '%维修综合%' AND c.ability_list NOT LIKE '%维修家电%' THEN '维修综合'
            WHEN c.ability_list LIKE '%维修家电%' AND c.ability_list NOT LIKE '%维修综合%' THEN '维修家电'
            WHEN c.ability_list LIKE '%维修综合%' AND c.ability_list LIKE '%维修家电%' THEN '维修综合家电'
            ELSE '其他'
        END AS `技能类型`
    FROM (
        SELECT 
            order_no,
            order_create_time,
            service_order_professional_ucid,
            service_order_professional_name,
            service_order_supplier_name,
            city_name,
            manager_marketing_name,
            label_group,
            lease_status,
            performance_mode,
            service_order_code,
            -- 从商品项中提取shelf_code（格式：shelf_code:::商品名称|...）
            SPLIT(SPLIT(commodity_item, '\\|')[0], ':::')[0] AS shelf_code,
            -- 从商品项中提取商品名称
            SPLIT(SPLIT(commodity_item, '\\|')[0], ':::')[1] AS commodity_name
        FROM olap.olap_hj_fas_main_order_service_info_da
        LATERAL VIEW EXPLODE(SPLIT(order_commodity_list, '\\|\\|\\|')) t AS commodity_item  -- 按|||分隔多个商品
        WHERE pt = '${-1d_pt}'
        AND order_type = 16
        AND label_group NOT IN ('8')  -- 排除标签组8
        AND to_date(order_create_time) = '2025-02-09'
        AND service_order_professional_ucid IS NOT NULL
        AND service_order_professional_ucid != -911  -- 排除异常UCID
        AND order_commodity_list IS NOT NULL
        AND order_commodity_list != ''
    ) a
    LEFT JOIN (
        SELECT DISTINCT 
            shelf_code,
            commodity_code
        FROM ods.ods_plat_jiafu_dispatch_capacity_dispatch_stream_log_ha
        WHERE pt = '${-1d_pt}'
        AND shelf_code IS NOT NULL
        AND commodity_code IS NOT NULL
    ) b ON a.shelf_code = b.shelf_code
    LEFT JOIN (
        SELECT DISTINCT 
            staff_ucid,
            ability_list,
            supplier_name
        FROM olap.olap_fas_mht_staff_detail_da
        WHERE pt = '${-1d_pt}'
        AND staff_ucid IS NOT NULL
    ) c ON a.service_order_professional_ucid = c.staff_ucid
) main
ORDER BY order_create_time DESC, order_no, commodity_code
