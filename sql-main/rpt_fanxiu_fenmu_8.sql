insert overwrite table rpt.rpt_fanxiu_fenmu_8 partition (pt='${-1d_pt}')

SELECT DISTINCT 
    a.city_name,
    a.service_order_supplier_name, 
    a.service_order_professional_ucid,
    a.service_order_professional_name,
    a.house_resource_id,
    a.service_order_complete_time,
    
    CASE 
        WHEN (a.examine_task_type = 3) OR (a.examine_task_type NOT IN (3,12) AND a.lease_status IN (-1,1)) 
        THEN '检修'  
        ELSE '租后维修' 
    END AS `维修类型`,
    
    CASE WHEN a.order_no IS NOT NULL THEN CONCAT(c.product_code, '-', a.order_no) END AS `8月完单商品`,
    CASE WHEN CONCAT(c.product_code, '-', a.order_no) IS NOT NULL THEN a.order_no END AS `8月完单号`,
    CASE WHEN CONCAT(c.product_code, '-', a.order_no) IS NOT NULL THEN c.product_name END AS `8月完单商品`,a.service_order_supplier_code
   
FROM (
   
    SELECT  
        r1.city_name 
        ,
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
        r1.service_order_professional_name,r1.service_order_supplier_code
    FROM (
        -- 原有主表查询逻辑
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
            a1.house_resource_id,a1.service_order_supplier_code
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
                house_resource_id,service_order_supplier_code
            FROM olap.olap_hj_fas_main_order_service_info_da
            WHERE pt ='${-1d_pt}'
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
-- 关联c表获取商品信息
JOIN (
    SELECT DISTINCT 
        service_order_code,
        product_name,
        product_code
    FROM dw.dw_fas_jiafu_dispatch_service_order_product_da
    WHERE pt = '${-1d_pt}'
    AND product_name RLIKE ('马桶|空调|洗手池|洗衣机|燃气灶|淋浴器|空 调|燃 气 灶|马 桶')
) c ON a.service_order_code = c.service_order_code