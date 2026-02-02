

WITH numbers AS (
    -- 构建考核月份及对应的起租日筛选区间
    SELECT
        CASE 
            WHEN n <= 12 THEN CONCAT('2025', '-', LPAD(n, 2, '0'))
            ELSE CONCAT('2026', '-', LPAD(n - 12, 2, '0'))
        END AS exam_month,
        city_name,
        -- 考核周期开始：当月1日往前推15天
        CASE 
            WHEN n <= 12 THEN date_sub(to_date(CONCAT('2025', '-', LPAD(n, 2, '0'), '-01')), 15)
            ELSE date_sub(to_date(CONCAT('2026', '-', LPAD(n - 12, 2, '0'), '-01')), 15)
        END AS rent_start,
        -- 考核周期结束：当月月底往前推15天
        CASE 
            WHEN n <= 12 THEN date_sub(last_day(to_date(CONCAT('2025', '-', LPAD(n, 2, '0'), '-01'))), 15)
            ELSE date_sub(last_day(to_date(CONCAT('2026', '-', LPAD(n - 12, 2, '0'), '-01'))), 15)
        END AS rent_end
    FROM (
        SELECT n, city_name
        FROM (SELECT stack(8, 6, 7, 8, 9, 10, 11, 12, 13) AS n) t1  -- 6-13对应2025.06-2026.01
        LATERAL VIEW EXPLODE(ARRAY('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')) t2 AS city_name  
    ) t
),

-- 获取订单商圈信息
order_bizcircle AS (
    SELECT DISTINCT
        order_no,
        service_order_supplier_name,
        service_order_professional_name,
        bizcircle_name
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '20260129000000'
        AND order_type = 16
),

-- t1: 核心出房房源 + 检修信息
t1 AS (
    SELECT 
        a.`城市名称`,
        COALESCE(ob.bizcircle_name, '') AS `商圈名称`,
        COALESCE(ob.service_order_supplier_name, '') AS `供应商`,
        COALESCE(ob.service_order_professional_name, '') AS `服务者`,
        a.`出房起租月`,
        a.`出房起租日`,
        a.`资管公司名称`,
        a.`大区`,
        a.`区域`,
        a.`合同编码`,
        a.`首出or非首出`,
        a.`是否有效排查`,
        a.`是否报修家服订单`,
        a.`是否在签约日完成排查`,
        a.`是否在签约日完成检和修`,
        a.effect_start_date,
        a.task_finish_time,
        a.trusteeship_housedel_code,
        a.order_finish_time,
        a.order_code,
        n.exam_month,
    FROM (
        SELECT DISTINCT aa.*
        FROM (
            SELECT DISTINCT 
                substr(effect_start_date, 1, 7) AS `出房起租月`,
                substr(effect_start_date, 1, 10) AS `出房起租日`,
                effect_start_date,
                property_submit_time,
                trusteeship_housedel_code,
                city_name AS `城市名称`,
                manager_corp_name AS `资管公司名称`,
                manager_marketing_name AS `大区`,
                manager_area_name AS `区域`,
                contract_code AS `合同编码`,
                CASE WHEN delivery_houseout_rank = 1 THEN '首出' 
                     WHEN delivery_houseout_rank > 1 THEN '非首出' 
                     ELSE NULL END `首出or非首出`,
                is_effective_examine AS `是否有效排查`,
                order_code,
                order_finish_time,
                IF(order_code != '', '有报修订单', '未报修订单') AS `是否报修家服订单`,
                CASE WHEN property_submit_time <> '1000-01-01 00:00:00' 
                     AND substr(property_submit_time, 1, 10) < substr(sign_date, 1, 10) 
                     THEN '签约前排查' ELSE '签约后排查' END AS `是否在签约日完成排查`,
                CASE WHEN property_submit_time <> '1000-01-01 00:00:00' 
                     AND substr(task_finish_time, 1, 10) < substr(sign_date, 1, 10) 
                     THEN '签约前完成维修' ELSE '签约后完成维修' END AS `是否在签约日完成检和修`,
                DENSE_RANK() OVER(PARTITION BY contract_code ORDER BY property_submit_time DESC) AS tijiao,
                task_finish_time
            FROM olap.olap_trusteeship_hdel_examine_divide_da
            WHERE pt = '20260129000000'
              AND task_type <> 12
              AND city_name IN ('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')
        ) aa
    ) a
    INNER JOIN numbers n 
        ON a.`出房起租日` BETWEEN n.rent_start AND n.rent_end  
        AND a.`城市名称` = n.city_name  
    LEFT JOIN order_bizcircle ob
        ON a.order_code = ob.order_no
    WHERE a.tijiao = 1 
),

-- 商品与服务映射辅助表
commodity_service_mapping AS (
    SELECT
        order_no,
        service_order_code,
        commodity_name,
        commodity_type,
        fault_list,
        fault_desc
    FROM olap.olap_hj_fas_main_order_commodity_da
    WHERE pt = '20260129000000'
),

commodity_all AS (
  SELECT DISTINCT 
        service_order_code,
        product_name
    FROM dw.dw_fas_jiafu_dispatch_service_order_product_da
    WHERE pt ='20260129000000'
    and  product_name not in ('机械锁（入户门）','夏季空调预检', 'SCM00300001672373', '漏水专项检修', '消防器材', '定损', '漏水定损', '火灾定损', '其他定损', '京北漏水定损', '京南漏水定损', '京北火灾定损', '京南火灾定损', '京北其他定损', '京南其他定损')
),
  
order_function AS (
  SELECT DISTINCT
    service_order_code,
    product_name,
    function_name 
  FROM rpt.rpt_fas_jiafu_dispatch_service_order_product_da
  WHERE pt = '20260129000000'
    AND function_name != '' 
    AND function_name IS NOT NULL
),

-- t2: 基础完工订单（初始维修单 - 分母）
base_complete_orders AS (
    SELECT DISTINCT
        a.house_resource_id,
        a.order_no AS complete_order_no,
        a.service_order_complete_time,
        a.city_name,
        d.function_name,
        c.product_name
    FROM (
        SELECT DISTINCT
            house_resource_id,
            service_order_complete_time,
            city_name,
            order_no,
            service_order_code
        FROM olap.olap_hj_fas_main_order_service_info_da
        WHERE pt = '20260129000000'
            AND order_type = 16
            AND label_group NOT IN ('8')
            AND TO_DATE(service_order_complete_time) >= '2025-10-01'
            AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
    ) a
    -- 关联功能间
    LEFT JOIN order_function d 
        ON a.service_order_code = d.service_order_code
    -- 关联标准商品名
    LEFT JOIN commodity_all c
        ON d.service_order_code = c.service_order_code 
        AND d.product_name = c.product_name
    -- 过滤安装类故障
    LEFT JOIN commodity_service_mapping sc 
        ON a.order_no = sc.order_no 
        AND sc.commodity_type = 1 
    WHERE (NVL(sc.fault_list,'') NOT LIKE '%安装%' AND NVL(sc.fault_desc,'') NOT LIKE '%安装%')
      AND sc.commodity_name RLIKE ('冰箱|电热水器|空调|燃气灶|燃气热水器/壁挂炉|洗衣机|油烟机|中央空调|窗帘|窗户|灯具|电线/插座|柜子|晾衣杆|淋浴房|淋浴器|楼梯|马桶|门|排风扇|墙面|天花板/吊顶|洗手池|浴霸')
      AND c.product_name IS NOT NULL
      AND d.function_name IS NOT NULL
),

-- t3: 再次下单的数据（返修单 - 分子）
molecule_orders AS (
    SELECT 
        a.order_no AS `分子订单号`,
        a.order_create_time AS `分子订单时间`,
        a.function_room_name AS `下单功能间名称`,
        sc.commodity_name AS `下单商品名称`,
        a.house_resource_id
    FROM ( 
        SELECT 
            mo.order_no,
            mo.order_create_time,
            mo.house_resource_id,
            regexp_extract(split(mo.item, '\\|')[2], ':::(.*)', 1) AS function_room_name
        FROM ( 
            SELECT 
                house_resource_id,
                order_create_time,
                order_no, 
                explode(split(order_commodity_list, '\\|\\|\\|')) AS item
            FROM olap.olap_hj_fas_main_order_service_info_da
            WHERE pt = '20260129000000'
              AND label_group NOT IN (8,13,'1','25')
              AND lease_status IN (2,3) -- 租后
              AND order_type = 16 
        ) mo
    ) a
    LEFT JOIN commodity_service_mapping sc 
        ON a.order_no = sc.order_no 
    WHERE NVL(sc.fault_list,'') NOT LIKE '%安装%' 
      AND NVL(sc.fault_desc,'') NOT LIKE '%安装%'
)

-- 最终明细查询
SELECT    
    -- 维度信息
    t1.exam_month AS `考核月`,
    t1.`城市名称`,
    t1.`商圈名称`,
    t1.`资管公司名称`,
    t1.`大区`,
    t1.`区域`,
    t1.`供应商`,
    t1.`服务者`,
    
    -- 房源与检修信息
    t1.`合同编码`,
    t1.trusteeship_housedel_code AS `房源编码`,
    t1.`出房起租日`,
    t1.effect_start_date AS `起租时间`,
    t1.`首出or非首出`,
    t1.`是否在签约日完成排查`,
    t1.order_code AS `关联的报修订单号`,

    -- 初始维修详情 (分母)
    t2.complete_order_no AS `初始维修订单号`,
    t2.service_order_complete_time AS `维修完工时间`,
    t2.function_name AS `维修功能间`,
    t2.product_name AS `维修商品`,

    -- 返修详情 (分子)
    t3.`分子订单号` AS `返修订单号`,
    t3.`分子订单时间` AS `返修下单时间`,
    t3.`下单功能间名称` AS `返修功能间`,
    t3.`下单商品名称` AS `返修商品`,
    
    -- 判定标记
    CASE WHEN t3.`分子订单号` IS NOT NULL THEN '是' ELSE '否' END AS `是否产生租后返修`,
    DATEDIFF(TO_DATE(t3.`分子订单时间`), TO_DATE(t1.`出房起租日`)) AS `起租后第几天返修`

FROM t1
-- 关联初始维修单 (通过检修单号关联)
LEFT JOIN base_complete_orders t2
    ON t1.order_code = t2.complete_order_no  

-- 关联租后返修单 (同房源、同功能间、同商品、起租后0-15天)
LEFT JOIN molecule_orders t3
    ON t2.house_resource_id = t3.house_resource_id  
    AND t2.function_name = t3.`下单功能间名称` 
    AND t2.product_name = t3.`下单商品名称`
    AND t3.`分子订单时间` > t1.`出房起租日`
    AND DATEDIFF(TO_DATE(t3.`分子订单时间`), TO_DATE(t1.`出房起租日`)) BETWEEN 0 AND 15

ORDER BY 
    t1.exam_month, 
    t1.`城市名称`, 
    t1.`商圈名称`, 
    t1.`合同编码`;