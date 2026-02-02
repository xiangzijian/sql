--模板查询：11
WITH numbers AS (
    SELECT
        CONCAT('2025', '-', LPAD(n, 2, '0')) AS exam_month,  
        city_name,
        date_sub(to_date(CONCAT('2025', '-', LPAD(n, 2, '0'), '-01')), 15) AS rent_start,
        date_sub(last_day(to_date(CONCAT('2025', '-', LPAD(n, 2, '0'), '-01'))), 15) AS rent_end
    FROM (
        SELECT n, city_name
        FROM (SELECT stack(8, 4,5,6,7,8,9,10,11) AS n) t1  
        LATERAL VIEW EXPLODE(ARRAY('苏州市','成都市','南京市')) t2 AS city_name  
    ) t
),

-- 第二步：核心出房房源+最后一次检修信息（仅北京市，新增2个字段）
t1 AS (
    SELECT 
  a. `城市名称`,
        a.`出房起租月`,
        a.`出房起租日`,
        a.`城市名称`,
        a.`资管公司名称`,
        a.`大区`,
        a.`区域`,
        a.`合同编码`,
        a.`首出or非首出`,
        a.`是否有效排查`,
        a.`是否报修家服订单`,
        a.`是否在签约日完成排查`,
        a.`是否在签约日完成检和修`,
        a.effect_start_date,  -- 新增：完整起租时间（含时分秒）
        a.task_finish_time,
        a.trusteeship_housedel_code,
        a.order_finish_time,
        a.order_code,  -- 报修订单号
        n.exam_month,a.property_submit_time  -- 关联考核月
    FROM (
        SELECT DISTINCT aa.*
        FROM (
            SELECT DISTINCT 
                substr(effect_start_date, 1, 7) AS `出房起租月`,
                substr(effect_start_date, 1, 10) AS `出房起租日`,
		  effect_start_date,property_submit_time,
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
                effect_start_date,  -- 原始字段：完整起租时间（格式：yyyy-MM-dd HH:mm:ss）
                task_finish_time    -- 原始字段：检修完成时间（格式：yyyy-MM-dd HH:mm:ss）
            FROM olap.olap_trusteeship_hdel_examine_divide_da
            WHERE pt = '20251203000000'
              AND task_type <> 12
              AND city_name in ('苏州市','成都市','南京市')
		
		  
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
        commodity_type -- 1=下单，2=完单
    FROM olap.olap_hj_fas_main_order_commodity_da
    WHERE pt = '20251203000000'
 
),


commodity_all as (
  SELECT DISTINCT 
        service_order_code,
        product_name
    FROM dw.dw_fas_jiafu_dispatch_service_order_product_da
    WHERE pt ='20251203000000'
  and  product_name not in ('机械锁（入户门）','京南漏水定损','京南其他定损')
),
  
order_function AS (  -- 修正表名拼写错误（原rder_function）
  SELECT DISTINCT
    service_order_code,product_name,
    function_name 
  FROM rpt.rpt_fas_jiafu_dispatch_service_order_product_da
  WHERE pt = '20251203000000' -- 统一pt分区
    AND function_name != '' 
    AND function_name IS NOT NULL
),

-- 基础完工订单：提取房源当月首次完工（按商品类型）的核心信息
base_complete_orders AS (
    SELECT DISTINCT
        a.house_resource_id,
        a.order_no AS complete_order_no,

        a.service_order_complete_time,
        SUBSTR(a.service_order_complete_time, 1, 7) AS complete_month, -- 完工月份（YYYY-MM）
        a.service_order_supplier_name,a.service_order_professional_ucid,
        a.city_name,a.service_order_code,
        c.product_name,
        d.function_name
    FROM (
        SELECT DISTINCT
            house_resource_id,
            service_order_complete_time,
            city_name,service_order_supplier_name,service_order_professional_ucid,
            order_no,service_order_code,
            CASE 
                WHEN city_name='北京市' AND manager_marketing_name IN ('京东事业部','京东南事业部','京东南租赁运营部','京东南运营','京东运营','京南事业部','京南大部','京南运营','京西南事业部','京西南运营') THEN '惠居京南'
                WHEN city_name='北京市' AND manager_marketing_name IN ('京东北事业部','京东北客户业务部','京东北运营','京中事业部','京中客户业务部','京中运营','京北事业部','京北大部','京北客户业务部','京北运营','京西事业部','京西北事业部','京西北客户业务部','京西北运营','京西客户业务部','京西运营') THEN '惠居京北'
            END AS `房管公司`
        FROM olap.olap_hj_fas_main_order_service_info_da
        WHERE pt = '20251203000000'
            AND order_type = 16
            AND label_group NOT IN ('8')
            AND city_name in ('苏州市','成都市','南京市')
            AND TO_DATE(service_order_complete_time) BETWEEN '2025-01-01' AND '2025-11-30' 
            AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
            AND service_order_complete_time IS NOT NULL
    ) a
    -- 关联完工订单的商品类型（commodity_type=2表示完单商品）
  
    LEFT JOIN order_function d  -- 修正表名引用
        ON a.service_order_code = d.service_order_code
  lEFT JOIN commodity_all c
        ON d.service_order_code  = c.service_order_code and  d.product_name = c.product_name
  
        
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
  WHERE pt = '20251203000000'
  and  label_group NOT IN (8,13,'1','25')
   and lease_status in (2,3)
    AND order_type = 16 
    AND city_name in ('苏州市','成都市','南京市')
  ) mo
   )a
 left JOIN commodity_service_mapping sc 
    ON a.order_no = sc.order_no 

 )
 

SELECT   t1.`城市名称`,
    t1.exam_month AS `考核月`,t2.service_order_supplier_name,
	t2.service_order_professional_ucid,
   count( distinct concat (t1.order_code,t2.function_name,t2.product_name)) as `检修完工商品量`,
   count( distinct concat (t3.`分子订单号`, t3.`下单功能间名称` ,t3.`下单商品名称`)) as `出租后商品量`
   
   
 
FROM t1

LEFT JOIN base_complete_orders t2
    ON t1.order_code = t2.complete_order_no  

LEFT JOIN molecule_orders t3
    ON t2.house_resource_id = t3.house_resource_id  
    AND t2.function_name = t3.`下单功能间名称` 
    AND t2.product_name = t3.`下单商品名称`
    AND t3.`分子订单时间` > t1.`出房起租日`
    AND DATEDIFF(TO_DATE(t3.`分子订单时间`), TO_DATE(t1.`出房起租日`)) BETWEEN 0 AND 15
group by 1,2,3,4
