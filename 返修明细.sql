SELECT DISTINCT a.`城市`,a.`供应商`,a.`服务者ucid`,a.`服务者姓名`,a.`房源编码`,a.`完工时间`
,a.`维修类型`,a.`完工订单号`,a.`完工商品名称`,b.`返修单号`,b.`关联单号`,b.`返修时间`,b.`返修商品`,b.`返修商品名称`,
t4.service_order_professional_name as `返修服务者姓名`,t4.service_order_professional_ucid as `返修服务者ucid`,
t4.service_order_supplier_name  as `返修商`,	a.supplier_code
FROM 
(
    SELECT 
        '${-1d_pt}' AS `分区字段`,
        a.city_name AS `城市`, 
        a.service_order_supplier_name AS `供应商`,
        a.service_order_supplier_code AS supplier_code,
        a.service_order_professional_ucid AS `服务者ucid`,
        a.service_order_professional_name AS `服务者姓名`,
        a.house_resource_id AS `房源编码`, 
        a.service_order_complete_time AS `完工时间`, 
        CASE 
            WHEN (a.examine_task_type = 3) OR (a.examine_task_type NOT IN (3,12) AND a.lease_status IN (-1,1)) 
            THEN '检修'  
            ELSE '租后维修' 
        END AS `维修类型`, 
        CASE WHEN a.order_no IS NOT NULL THEN CONCAT(c.product_code, '-', a.order_no) END AS `完工订单号+商品`, 
        CASE WHEN CONCAT(c.product_code, '-', a.order_no) IS NOT NULL THEN a.order_no END AS `完工订单号`,
        CASE WHEN CONCAT(c.product_code, '-', a.order_no) IS NOT NULL THEN c.product_name END AS `完工商品名称`
    FROM (
        SELECT  
            r1.city_name,
            r1.service_order_supplier_name,
            r1.service_order_complete_time,
            r1.lease_status, 
            r1.order_no,
            r1.service_order_code,
            r1.house_resource_id,
            r1.order_create_time,
            r1.label_group,
            r1.service_order_professional_ucid,
            r1.examine_task_type,
            r1.service_order_professional_name,
            r1.service_order_supplier_code
        FROM (
            SELECT 
                a1.order_no,
                a1.service_order_code,
                a1.service_order_complete_time,
                a1.order_create_time,
                a1.manager_corp_name,
                a1.examine_task_type,
                a1.lease_status,
                a1.city_name,
                a1.service_order_supplier_name,
                a1.label_group,
                a1.service_order_professional_ucid,
                a1.service_order_professional_name,
                a1.house_resource_id,
                a1.service_order_supplier_code
            FROM (
                SELECT DISTINCT
                    order_no,
                    service_order_code,
                    service_order_complete_time,
                    service_order_professional_ucid,
                    examine_task_type,
                    lease_status,
                    order_create_time,
                    manager_corp_name,
                    city_name,
                    service_order_supplier_name,
                    label_group,
                    service_order_professional_name,
                    house_resource_id,
                    service_order_supplier_code
                FROM olap.olap_hj_fas_main_order_service_info_da
                WHERE pt = '${-1d_pt}'
                AND order_type = 16
                AND label_group NOT IN ('8')
                AND to_date(service_order_complete_time) >= '2025-06-01'
            ) a1
            INNER JOIN (
                SELECT
                    order_no AS oth_orderno,
                    service_order_code,
                    create_time
                FROM rpt.rpt_fas_light_hosting_order_detail_da
                WHERE pt = '${-1d_pt}'
                AND vison_type = '4.0'
                AND service_name IN ('维修','燃气')
                AND order_type = '16'
                AND label_group NOT IN ('8')
                AND commodity_name_list1 != '漏水专项检修'
                AND commodity_code_list1 != 'SCM00300001672373'
                AND commodity_name_list1 NOT IN ('夏季空调预检','消防器材')
                AND supplier_name NOT IN (
                    '上海兰宫建筑装饰有限公司',
                    '上海尚礼实业有限公司',
                    '上海苏皖贸易有限公司',
                    '上海再旭保洁服务有限公司',
                    '源和里仁家具海安有限公司'
                )
            ) a2 ON a2.oth_orderno = a1.order_no
        ) r1
    ) a
    JOIN (
        SELECT DISTINCT 
            service_order_code,
            product_name,
            product_code
        FROM dw.dw_fas_jiafu_dispatch_service_order_product_da
        WHERE pt = '${-1d_pt}'
        AND product_name RLIKE ('马桶|空调|洗手池|洗衣机|燃气灶|淋浴器|空 调|燃 气 灶|马 桶')
    ) c ON a.service_order_code = c.service_order_code
    WHERE substr(a.service_order_complete_time,1,7)>='2025-08'
) a
LEFT JOIN 
(
    SELECT 
      n.`返修单号`,n.`关联单号`,n.`返修时间`,n.`返修商品`,n.`返修商品名称`
    FROM 
    (
        SELECT 
            r.order_code AS `返修单号`,
            r.relate_order_code AS `关联单号`,
            r.order_create_date AS `返修时间`,
            g.commodity_code AS `返修商品`,
            g.commodity_name AS `返修商品名称`,
            -- 新增：按关联单号分组，按返修时间倒序编号
            ROW_NUMBER() OVER(
                PARTITION BY r.relate_order_code, g.commodity_name 
                ORDER BY r.order_create_date 
            ) AS rn  -- 这个编号将用于取最近一次返修
        FROM 
        (
            SELECT 
                order_code,
                relate_order_code,
                order_create_date
            FROM rpt.rpt_plat_beijia_transaction_trade_order_relate_info_di
            WHERE pt BETWEEN '${-160d_pt}' AND '${-1d_pt}'
            AND relate_type = '1'
            AND del_status = '1'
        ) r
        JOIN 
        (
            SELECT 
                order_no,
                commodity_code,
                commodity_name
            FROM olap.olap_hj_fas_main_order_commodity_da
            WHERE pt='${-1d_pt}'
            AND commodity_type = 1
            AND commodity_name RLIKE ('马桶|空调|洗手池|洗衣机|燃气灶|淋浴器|空 调|燃 气 灶|马 桶')
            -- AND manager_corp_name = '惠居京北'
        ) g ON g.order_no = r.order_code
    ) n
    WHERE n.rn = 1  -- 只保留最近一次返修记录
) b 
ON a.`完工订单号` = b.`关联单号` AND a.`完工商品名称` = b.`返修商品名称`
left join 
 (select order_no,service_order_professional_name, service_order_professional_ucid,service_order_supplier_name 
 
 FROM 
    olap.olap_hj_fas_main_order_service_info_da
    where pt='${-1d_pt}'
    AND order_type = 16
    AND label_group NOT IN ('8'))
	t4
	on t4.order_no=b.`返修单号`