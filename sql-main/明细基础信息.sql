insert overwrite table rpt.rpt_relate_order_code_8 partition (pt='${-1d_pt}')

SELECT DISTINCT a.`城市`,a.`供应商`,a.`服务者ucid`,a.`服务者姓名`,a.`房源编码`,a.`完工时间`
,a.`维修类型`,a.`完工订单号`,a.`完工商品名称`,b.`返修单号`,b.`关联单号`,b.`返修时间`,b.`返修商品`,b.`返修商品名称`,
t4.service_order_professional_name as `返修服务者姓名`,t4.service_order_professional_ucid as `返修服务者ucid`,
t4.service_order_supplier_name  as `返修商`,	a.supplier_code
FROM 
(
    SELECT 
        pt AS `分区字段`,
        city_name AS `城市`, 
        service_order_supplier_name AS `供应商`,
  	supplier_code,
        service_order_professional_ucid AS `服务者ucid`,
        service_order_professional_name AS `服务者姓名`,
        house_resource_id AS `房源编码`, 
        service_order_complete_time AS `完工时间`, 
        task_type AS `维修类型`, 
        order_no AS `完工订单号+商品`, 
        order_no1 AS `完工订单号`,
        product_name AS `完工商品名称`
    FROM rpt.rpt_fanxiu_fenmu_8
    WHERE  pt='${-1d_pt}'
  and substr(service_order_complete_time,1,7)>='2025-08'
    
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