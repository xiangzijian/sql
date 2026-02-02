--模板查询：检修返修-新口径 限制商品
WITH numbers AS (
    SELECT
        CONCAT('2025', '-', LPAD(n, 2, '0')) AS exam_month,  
        city_name,
        date_sub(to_date(CONCAT('2025', '-', LPAD(n, 2, '0'), '-01')), 15) AS rent_start,
        date_sub(last_day(to_date(CONCAT('2025', '-', LPAD(n, 2, '0'), '-01'))), 15) AS rent_end
    FROM (
        SELECT n, city_name
        FROM (SELECT stack(7, 6,7,8,9,10,11,12) AS n) t1  
        LATERAL VIEW EXPLODE(ARRAY('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')) t2 AS city_name  
    ) t
),

-- 第二步：核心出房房源+最后一次检修信息（仅北京市，新增2个字段）
t1 AS (
    SELECT 
        a.`出房起租日`,
        a.`城市名称`,
        a.order_code,
        n.exam_month
    FROM (
        SELECT DISTINCT aa.*
        FROM (
            SELECT DISTINCT 
                substr(effect_start_date, 1, 10) AS `出房起租日`,
                city_name AS `城市名称`,
                order_code,
                contract_code,
                property_submit_time,
                DENSE_RANK() OVER(PARTITION BY contract_code ORDER BY property_submit_time DESC) AS tijiao
            FROM olap.olap_trusteeship_hdel_examine_divide_da
            WHERE pt = '20250125000000'
              AND task_type <> 12
              AND city_name in ('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')
        ) aa
    ) a
    -- 关联考核月区间，筛选符合条件的房源
    INNER JOIN numbers n 
        ON a.`出房起租日` BETWEEN n.rent_start AND n.rent_end  
        AND a.`城市名称` = n.city_name  
    WHERE a.tijiao = 1 
),

commodity_service_mapping AS (
    SELECT
        order_no,
        service_order_code,
        commodity_name,
        commodity_type,
        fault_list,
        fault_desc
    FROM olap.olap_hj_fas_main_order_commodity_da
    WHERE pt = '20250125000000'
 
),


commodity_all as (
  SELECT DISTINCT 
        service_order_code,
        product_name
    FROM dw.dw_fas_jiafu_dispatch_service_order_product_da
    WHERE pt ='20250125000000'
  and  product_name not in ('机械锁（入户门）','夏季空调预检', 'SCM00300001672373', '漏水专项检修', '消防器材', '定损', '漏水定损', '火灾定损', '其他定损', '京北漏水定损', '京南漏水定损', '京北火灾定损', '京南火灾定损', '京北其他定损', '京南其他定损')
),
  
order_function AS (  -- 修正表名拼写错误（原rder_function）
  SELECT DISTINCT
    service_order_code,product_name,
    function_name 
  FROM rpt.rpt_fas_jiafu_dispatch_service_order_product_da
  WHERE pt = '20250125000000' -- 统一pt分区
    AND function_name != '' 
    AND function_name IS NOT NULL
),

-- 获取所有商圈列表
all_bizcircles AS (
    SELECT DISTINCT
        city_name,
        bizcircle_name
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '20250125000000'
        AND city_name in ('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')
        AND bizcircle_name IS NOT NULL
        AND bizcircle_name != ''
),

-- 构建完整的城市×考核月×商圈组合
city_month_bizcircle AS (
    SELECT 
        n.city_name AS `城市名称`,
        n.exam_month AS `考核月`,
        b.bizcircle_name AS `商圈`
    FROM numbers n
    CROSS JOIN all_bizcircles b
    WHERE n.city_name = b.city_name
),

-- 基础完工订单：提取房源当月首次完工（按商品类型）的核心信息
base_complete_orders AS (
    SELECT DISTINCT
        a.house_resource_id,
        a.order_no AS complete_order_no,
        c.product_name,
        d.function_name,
        a.bizcircle_name,
        a.city_name
    FROM (
        SELECT DISTINCT
            house_resource_id,
            order_no,
            service_order_code,
            service_order_complete_time,
            city_name,
            bizcircle_name
        FROM olap.olap_hj_fas_main_order_service_info_da
        WHERE pt = '20250125000000'
            AND order_type = 16
            AND label_group NOT IN ('8')
            AND city_name in ('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')
            AND TO_DATE(service_order_complete_time) BETWEEN '2025-06-01' AND '2025-12-31' 
            AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
            AND service_order_complete_time IS NOT NULL
    ) a
    -- 关联完工订单的商品类型（commodity_type=2表示完单商品）
  
    LEFT JOIN order_function d  -- 修正表名引用
        ON a.service_order_code = d.service_order_code
  lEFT JOIN commodity_all c
        ON d.service_order_code  = c.service_order_code and  d.product_name = c.product_name
   left Join commodity_service_mapping sc on a.order_no = sc.order_no and sc.commodity_type = 1 
   where  ( NVL(sc.fault_list,'') NOT LIKE '%安装%'  AND NVL(sc.fault_desc,'') NOT LIKE '%安装%' ) 
  and sc.commodity_name RLIKE ('冰箱|电热水器|空调|燃气灶|燃气热水器/壁挂炉|洗衣机|油烟机|中央空调|窗帘|窗户|灯具|电线/插座|柜子|晾衣杆|淋浴房|淋浴器|楼梯|马桶|门|排风扇|墙面|天花板/吊顶|洗手池|浴霸')
),

-- 再次下单的数据（分子）：修正关联表和字段
molecule_orders AS (
 
  select a.order_no as `分子订单号`,
  a.order_create_time  as `分子订单时间`,
  a.function_room_name as `下单功能间名称` ,
  sc.commodity_name as `下单商品名称`,
  a.house_resource_id
  from 
  ( SELECT  mo.order_no,mo.order_create_time,mo.house_resource_id,
  
  regexp_extract(
    split(mo.item, '\\|')[2],  
    ':::(.*)',  
    1
  ) as function_room_name
  from 
  ( SELECT 
    house_resource_id,order_create_time,
    order_no, explode(split(order_commodity_list, '\\|\\|\\|')) as item
  FROM olap.olap_hj_fas_main_order_service_info_da
  WHERE pt = '20250125000000'
  and  label_group NOT IN (8,13,'1','25')
   and lease_status in (2,3)
    AND order_type = 16 
    AND city_name in ('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')
  ) mo
   )a
 left JOIN commodity_service_mapping sc 
    ON a.order_no = sc.order_no 
    where  NVL(sc.fault_list,'') NOT LIKE '%安装%'  AND NVL(sc.fault_desc,'') NOT LIKE '%安装%'
 )
 

SELECT   
    cmb.`城市名称`,
    cmb.`考核月`,
    cmb.`商圈`,
    COUNT(DISTINCT CONCAT(t1.order_code, t2.function_name, t2.product_name)) AS `检修完工商品量`,
    COUNT(DISTINCT CONCAT(t3.`分子订单号`, t3.`下单功能间名称`, t3.`下单商品名称`)) AS `出租后商品量`
FROM city_month_bizcircle cmb

-- 关联出房数据
LEFT JOIN t1
    ON cmb.`城市名称` = t1.`城市名称`
    AND cmb.`考核月` = t1.exam_month

-- 关联完工订单（需要匹配城市、商圈）
LEFT JOIN base_complete_orders t2
    ON t1.order_code = t2.complete_order_no
    AND cmb.`城市名称` = t2.city_name
    AND cmb.`商圈` = t2.bizcircle_name

-- 关联再次下单数据
LEFT JOIN molecule_orders t3
    ON t2.house_resource_id = t3.house_resource_id  
    AND t2.function_name = t3.`下单功能间名称` 
    AND t2.product_name = t3.`下单商品名称`
    AND t3.`分子订单时间` > t1.`出房起租日`
    AND DATEDIFF(TO_DATE(t3.`分子订单时间`), TO_DATE(t1.`出房起租日`)) BETWEEN 0 AND 15

GROUP BY cmb.`城市名称`, cmb.`考核月`, cmb.`商圈`
ORDER BY cmb.`城市名称`, cmb.`考核月`, cmb.`商圈`