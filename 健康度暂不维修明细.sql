
    SELECT 
        j.month_string AS `月份`,
        j.city_name AS `城市`,
        j.service_order_supplier_name AS `供应商`,
        j.service_order_professional_name AS `服务者`,
        j.order_no AS `单号`,
        j.order_create_time AS `创建时间`,
        j.service_order_complete_time AS `完工时间`,
        j.gong_time AS `工时`,
        p.function_name AS `功能间`,
        p.product_name AS `商品`,
        '' AS `故障项`,
        j.label_group11 AS `检修/租后`,
        j.rea AS `是否标记暂不维修`,
        j.reason AS `暂不维修原因-1级`,
        p.reason AS `暂不维修原因-2级`
    FROM (select * from rpt.rpt_jiankandumingxi1 where pt='${-1d_pt}') j
    LEFT JOIN 
      ( select service_order_code,concat_ws(';', collect_set(reason)) as reason ,
        function_name,product_name
        from rpt.rpt_fas_jiafu_dispatch_service_order_product_da where pt='${-1d_pt}' 
        and reason_code in (104,105,108,101,102,103,106,107,109,110,111,112) group by service_order_code,function_name,product_name ) p
        ON j.service_order_code = p.service_order_code
    
    


