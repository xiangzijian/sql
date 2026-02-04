-- 统计时间：2025年6月-2026年1月
WITH numbers AS (
    SELECT
        CASE 
            WHEN n <= 12 THEN CONCAT('2025', '-', LPAD(n, 2, '0'))
            ELSE CONCAT('2026', '-', LPAD(n - 12, 2, '0'))
        END AS exam_month,
        city_name,
        CASE 
            WHEN n <= 12 THEN date_sub(to_date(CONCAT('2025', '-', LPAD(n, 2, '0'), '-01')), 15)
            ELSE date_sub(to_date(CONCAT('2026', '-', LPAD(n - 12, 2, '0'), '-01')), 15)
        END AS rent_start,
        CASE 
            WHEN n <= 12 THEN date_sub(last_day(to_date(CONCAT('2025', '-', LPAD(n, 2, '0'), '-01'))), 15)
            ELSE date_sub(last_day(to_date(CONCAT('2026', '-', LPAD(n - 12, 2, '0'), '-01'))), 15)
        END AS rent_end
    FROM (
        SELECT n, city_name
        FROM (SELECT stack(8, 6,7,8,9,10,11,12,13) AS n) t1
        LATERAL VIEW EXPLODE(ARRAY('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')) t2 AS city_name  
    ) t
),

order_bizcircle AS (
    SELECT DISTINCT
        order_no,
        bizcircle_name
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${-1d_pt}'
        AND order_type = 16
),

t1 AS (
    SELECT 
        a.`城市名称`,
        COALESCE(ob.bizcircle_name, '') AS `商圈名称`,
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
        a.property_submit_time
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
            WHERE pt = '${-1d_pt}'
              AND task_type <> 12
              AND city_name IN ('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')
        ) aa
    ) a
    INNER JOIN numbers n ON a.`城市名称` = n.city_name
    LEFT JOIN order_bizcircle ob ON a.order_code = ob.order_no
    WHERE a.tijiao = 1 
      AND a.`出房起租日` BETWEEN n.rent_start AND n.rent_end
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
    WHERE pt = '${-1d_pt}'
),

commodity_all AS (
  SELECT DISTINCT 
        service_order_code,
        product_name
    FROM dw.dw_fas_jiafu_dispatch_service_order_product_da
    WHERE pt ='${-1d_pt}'
    AND product_name NOT IN ('夏季空调预检','SCM00300001672373','漏水专项检修','消防器材','定损','漏水定损','火灾定损','其他定损','京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损','京北其他定损','京南其他定损')
),
  
order_function AS (
  SELECT DISTINCT
    service_order_code,product_name,
    function_name 
  FROM rpt.rpt_fas_jiafu_dispatch_service_order_product_da
  WHERE pt = '${-1d_pt}'
    AND function_name != '' 
    AND function_name IS NOT NULL
),

base_complete_orders AS (
    SELECT DISTINCT
        a.house_resource_id,
        a.order_no AS complete_order_no,
        a.service_order_complete_time,
        SUBSTR(a.service_order_complete_time, 1, 7) AS complete_month,
        a.service_order_supplier_name,
        a.service_order_professional_ucid,
        a.city_name,
        a.bizcircle_name,
        a.service_order_code,
        c.product_name,
        d.function_name
    FROM (
        SELECT DISTINCT
            house_resource_id,
            service_order_complete_time,
            city_name,
            bizcircle_name,
            service_order_supplier_name,
            service_order_professional_ucid,
            order_no,
            service_order_code
        FROM olap.olap_hj_fas_main_order_service_info_da
        WHERE pt = '${-1d_pt}'
            AND order_type = 16
            AND label_group NOT IN ('8')
            AND city_name IN ('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')
            AND TO_DATE(service_order_complete_time) BETWEEN '2025-06-01' AND '2026-01-31'
            AND SUBSTR(service_order_complete_time, 1, 4) NOT IN ('1990','2050','1000')
            AND service_order_complete_time IS NOT NULL
    ) a
    LEFT JOIN order_function d ON a.service_order_code = d.service_order_code
    LEFT JOIN commodity_all c ON d.service_order_code = c.service_order_code AND d.product_name = c.product_name
    LEFT JOIN commodity_service_mapping sc ON a.order_no = sc.order_no AND sc.commodity_type = 1 
    WHERE NVL(sc.fault_list,'') NOT LIKE '%安装%' AND NVL(sc.fault_desc,'') NOT LIKE '%安装%' 
        AND sc.commodity_name RLIKE '冰箱|电热水器|空调|燃气灶|燃气热水器/壁挂炉|洗衣机|油烟机|中央空调|窗帘|窗户|灯具|电线/插座|柜子|晾衣杆|淋浴房|淋浴器|楼梯|马桶|门|排风扇|墙面|天花板/吊顶|洗手池|浴霸'
        AND c.product_name IS NOT NULL
        AND d.function_name IS NOT NULL
),

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
        t.item
      FROM olap.olap_hj_fas_main_order_service_info_da
      LATERAL VIEW explode(split(order_commodity_list, '\\|\\|\\|')) t AS item
      WHERE pt = '${-1d_pt}'
        AND label_group NOT IN ('8','13','1','25')
        AND lease_status IN (2,3)
        AND order_type = 16 
        AND city_name IN ('苏州市','成都市','南京市','上海市','北京市','天津市','宁波市','广州市','杭州市','武汉市','济南市','深圳市','西安市')
    ) mo
  ) a
  LEFT JOIN commodity_service_mapping sc ON a.order_no = sc.order_no 
  WHERE NVL(sc.fault_list,'') NOT LIKE '%安装%' AND NVL(sc.fault_desc,'') NOT LIKE '%安装%'
)

insert overwrite table rpt.rpt_jianxiu_fanxiu partition (pt='${-1d_pt}')
SELECT   
    t1.`城市名称`,
    t1.`商圈名称`,  
    t1.exam_month AS `考核月`,
    t1.`出房起租月`,
    t1.`出房起租日`,
    t1.`大区`,
    t1.`区域`,
    t1.`合同编码`,
    t1.effect_start_date,
    t1.task_finish_time,
    t1.trusteeship_housedel_code,
    t1.order_finish_time,
    t1.order_code AS `检修完工订单号`,
    t2.service_order_complete_time AS `检修完工时间`,
    t2.service_order_supplier_name AS `检修完工供应商`,
    t2.service_order_professional_ucid AS `检修完工师傅`,
    t2.function_name AS `检修功能间名称`,
    t2.product_name AS `检修商品名称`,
    t2.service_order_supplier_name AS `供应商`,
    -- 【核心修改：将非等值逻辑移到这里】
    IF(t3.`分子订单时间` > t1.`出房起租日` AND DATEDIFF(TO_DATE(t3.`分子订单时间`), TO_DATE(t1.`出房起租日`)) BETWEEN 0 AND 15, t3.`分子订单号`, NULL) AS `分子订单号`,
    IF(t3.`分子订单时间` > t1.`出房起租日` AND DATEDIFF(TO_DATE(t3.`分子订单时间`), TO_DATE(t1.`出房起租日`)) BETWEEN 0 AND 15, t3.`分子订单时间`, NULL) AS `分子订单时间`,
    IF(t3.`分子订单时间` > t1.`出房起租日` AND DATEDIFF(TO_DATE(t3.`分子订单时间`), TO_DATE(t1.`出房起租日`)) BETWEEN 0 AND 15, t3.`下单功能间名称`, NULL) AS `下单功能间名称`,
    IF(t3.`分子订单时间` > t1.`出房起租日` AND DATEDIFF(TO_DATE(t3.`分子订单时间`), TO_DATE(t1.`出房起租日`)) BETWEEN 0 AND 15, t3.`下单商品名称`, NULL) AS `下单商品名称`
FROM t1
LEFT JOIN base_complete_orders t2
    ON t1.order_code = t2.complete_order_no  
LEFT JOIN molecule_orders t3
    ON t2.house_resource_id = t3.house_resource_id  
    AND t2.function_name = t3.`下单功能间名称` 
    AND t2.product_name = t3.`下单商品名称`