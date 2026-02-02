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

-- 第二步：核心出房房源+最后一次检修信息
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
            WHERE pt = '20260125000000'
              AND task_type <> 12
              AND city_name = '广州市'
        ) aa
    ) a
    -- 关联考核月区间，筛选符合条件的房源
    INNER JOIN numbers n 
        ON a.`出房起租日` BETWEEN n.rent_start AND n.rent_end  
        AND a.`城市名称` = n.city_name  
        AND n.exam_month = '2025-12'  -- 筛选7月份
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
    WHERE pt = '20260125000000'
 
),

commodity_all as (
  SELECT DISTINCT 
        service_order_code,
        product_name
    FROM dw.dw_fas_jiafu_dispatch_service_order_product_da
    WHERE pt ='20260125000000'
  and  product_name not in ('机械锁（入户门）','夏季空调预检', 'SCM00300001672373', '漏水专项检修', '消防器材', '定损', '漏水定损', '火灾定损', '其他定损', '京北漏水定损', '京南漏水定损', '京北火灾定损', '京南火灾定损', '京北其他定损', '京南其他定损')
),
  
order_function AS (
  SELECT DISTINCT
    service_order_code,product_name,
    function_name 
  FROM rpt.rpt_fas_jiafu_dispatch_service_order_product_da
  WHERE pt = '20260125000000'
    AND function_name != '' 
    AND function_name IS NOT NULL
),

-- 基础完工订单：提取考核周期倒推15天起租的房子的检修完工订单（分母）
base_complete_orders AS (
    SELECT 
        t1.`出房起租日`,
        t1.`城市名称`,
        t1.order_code AS `出房订单号`,
        t1.exam_month,
        t2.house_resource_id,
        t2.complete_order_no,
        t2.product_name,
        t2.function_name,
        t2.bizcircle_name,
        t2.city_name,
        t2.service_order_complete_time,
        t2.complete_month
    FROM t1
    -- 关联检修完工订单（只关联t1中房子的检修完工订单）
    INNER JOIN (
        SELECT 
            house_resource_id,
            complete_order_no,
            product_name,
            function_name,
            bizcircle_name,
            city_name,
            service_order_complete_time,
            complete_month
        FROM (
            SELECT DISTINCT
                a.house_resource_id,
                a.order_no AS complete_order_no,
                c.product_name,
                d.function_name,
                a.bizcircle_name,
                a.city_name,
                a.service_order_complete_time,
                SUBSTR(a.service_order_complete_time, 1, 7) AS complete_month,
                ROW_NUMBER() OVER(PARTITION BY a.order_no, c.product_name, d.function_name ORDER BY a.service_order_complete_time) AS rn
            FROM (
                SELECT DISTINCT
                    house_resource_id,
                    order_no,
                    service_order_code,
                    service_order_complete_time,
                    city_name,
                    bizcircle_name
                FROM olap.olap_hj_fas_main_order_service_info_da
                WHERE pt = '20260125000000'
                    AND order_type = 16
                    AND label_group NOT IN ('8')
                    AND city_name = '广州市'
                    AND bizcircle_name = '花地湾'  -- 筛选东川路商圈
                    AND TO_DATE(service_order_complete_time) BETWEEN '2025-06-01' AND '2025-12-31' 
                    AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
                    AND service_order_complete_time IS NOT NULL
            ) a
            LEFT JOIN order_function d
                ON a.service_order_code = d.service_order_code
            LEFT JOIN commodity_all c
                ON d.service_order_code  = c.service_order_code and  d.product_name = c.product_name
            LEFT JOIN commodity_service_mapping sc on a.order_no = sc.order_no and sc.commodity_type = 1 
            WHERE  ( NVL(sc.fault_list,'') NOT LIKE '%安装%'  AND NVL(sc.fault_desc,'') NOT LIKE '%安装%' ) 
            AND sc.commodity_name RLIKE ('冰箱|电热水器|空调|燃气灶|燃气热水器/壁挂炉|洗衣机|油烟机|中央空调|窗帘|窗户|灯具|电线/插座|柜子|晾衣杆|淋浴房|淋浴器|楼梯|马桶|门|排风扇|墙面|天花板/吊顶|洗手池|浴霸')
            AND c.product_name IS NOT NULL
            AND d.function_name IS NOT NULL
        ) t
        WHERE rn = 1
    ) t2
    ON t1.order_code = t2.complete_order_no
    AND t1.`城市名称` = t2.city_name
),

-- 再次下单的数据（分子）
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
  WHERE pt = '20260125000000'
  and  label_group NOT IN (8,13,'1','25')
   and lease_status in (2,3)
    AND order_type = 16 
    AND city_name = '广州市'
  ) mo
   )a
 left JOIN commodity_service_mapping sc 
    ON a.order_no = sc.order_no 
    where  NVL(sc.fault_list,'') NOT LIKE '%安装%'  AND NVL(sc.fault_desc,'') NOT LIKE '%安装%'
 )

-- 明细查询：考核周期倒推15天起租的房子的检修完工商品明细，判断是否返修
-- 分母：考核周期倒推15天起租的房子的检修完工的商品量（功能间+商品组合）
-- 分子：这些检修完工的商品在起租日后15天内再次报修的同房-同功能间-同商品的量
SELECT DISTINCT
    t2.`城市名称` AS `城市`,
    t2.exam_month AS `考核月`,
    t2.bizcircle_name AS `商圈`,
    t2.`出房订单号`,
    t2.complete_order_no AS `检修完工订单号`,
    t2.product_name AS `商品名称`,
    t2.function_name AS `功能间名称`,
    t2.service_order_complete_time AS `检修完工时间`,
    t2.`出房起租日` AS `起租日`,
    t3.`分子订单号` AS `返修订单号`,
    t3.`下单商品名称` AS `返修商品名称`,
    t3.`下单功能间名称` AS `返修功能间名称`,
    t3.`分子订单时间` AS `返修订单时间`,
    CASE 
        WHEN t3.`分子订单号` IS NOT NULL THEN '是'
        ELSE '否'
    END AS `是否返修`,
    CASE 
        WHEN t3.`分子订单时间` IS NOT NULL 
        THEN DATEDIFF(TO_DATE(t3.`分子订单时间`), TO_DATE(t2.`出房起租日`))
        ELSE NULL
    END AS `返修间隔天数`
FROM base_complete_orders t2

-- 关联返修订单数据（分子：起租日后15天内再次报修的同房-同功能间-同商品）
LEFT JOIN molecule_orders t3
    ON t2.house_resource_id = t3.house_resource_id  
    AND t2.function_name = t3.`下单功能间名称` 
    AND t2.product_name = t3.`下单商品名称`
    AND t3.`分子订单时间` > t2.`出房起租日`  -- 返修订单时间在起租日之后
    AND DATEDIFF(TO_DATE(t3.`分子订单时间`), TO_DATE(t2.`出房起租日`)) BETWEEN 0 AND 15  -- 返修订单在起租日后0-15天内

ORDER BY `起租日`, `出房订单号`, `商品名称`, `功能间名称