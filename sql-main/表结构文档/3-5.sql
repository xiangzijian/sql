with tag1 as (select trusteeship_housedel_code,contract_code,
                  max(effect_start_date) effect_start_date,
                  max(houseout_rank) houseout_rank,
                  max(contract_sign_time) contract_sign_time,
                  max(delivery_date) as delivery_date,
                  max(fund_company_name) as fund_company_name,
                  max(fund_company_code) as fund_company_code,
                  max(manager_area_name) as manager_area_name  
                  from olap.olap_trusteeship_hdel_houseout_da 
                  where pt = '20260225000000' and effect_start_date >='2026-01-01' 
                  and city_name = '成都市'
                   group by trusteeship_housedel_code,contract_code),
    tag2 as (select order_no,
                  service_order_code,
                  max(house_resource_id) house_resource_id,
                  max(houseout_contract_code) houseout_contract_code,
                  max(city_name) city_name,
                  max(order_create_time) order_create_time,
                  max(service_order_supplier_name) service_order_supplier_name,
                  max(service_order_professional_name) service_order_professional_name,
                  max(service_order_professional_ucid) service_order_professional_ucid,
                  max(first_sign_time) first_sign_time
                  from olap.olap_hj_fas_main_order_service_info_da where pt = '20260225000000' and
                  order_create_time >= '2026-01-01' and order_type = 16 and label_group not in ('8') and lease_status in ('2', '3') 
                  group by order_no,service_order_code),
    tag3 as (
           SELECT order_no,
           -- 将同一个订单下的多个商品名用逗号拼接起来
           concat_ws(',', collect_set(commodity_name)) as commodity_name,
           -- 将多条故障信息也拼接起来
           concat_ws('|', collect_set(fault_list)) as fault_list
           FROM olap.olap_hj_fas_main_order_commodity_da
           WHERE pt='20260225000000'
           AND commodity_type = 1  
           AND commodity_name RLIKE ('马桶|空调|洗手池|洗衣机|燃气灶|淋浴器|空 调|燃 气 灶|马 桶')
           GROUP BY order_no
        ),
    tag4 as (
    select order_no,
           min(operate_type_create_time) operate_type_create_time,
           max(total_amount) total_amount,
           max(case when plan_status = 2 then 1 else 0 end) as success_flag
    from olap.olap_hj_fas_main_order_service_out_free_repair_plan_da where pt='20260225000000'   group by order_no
    )
   

select t2.city_name,
       t2.houseout_contract_code,
       t1.houseout_rank,
       t1.contract_sign_time,
       t1.delivery_date,
       t1.effect_start_date,
       t2.order_create_time,
       t1.fund_company_name,
       t1.fund_company_code,
       t1.manager_area_name,
       t2.order_no,
       t2.service_order_supplier_name,
       t2.service_order_professional_name,
       t2.service_order_professional_ucid,
       t2.first_sign_time,
       t3.commodity_name,
       t3.fault_list,
       t4.operate_type_create_time,
       t4.total_amount,
       t4.success_flag
        from tag1 t1 inner join tag2 t2 on t1.trusteeship_housedel_code = t2.house_resource_id and t1.contract_code = t2.houseout_contract_code 
       left join tag3 t3 on t2.order_no = t3.order_no  left join tag4 t4 on t2.order_no = t4.order_no 
       where 
       unix_timestamp(t2.order_create_time) <= unix_timestamp(t1.effect_start_date, 'yyyy-MM-dd') + (15 * 24 * 3600) and
       unix_timestamp(t2.order_create_time) >= unix_timestamp(t1.effect_start_date)


                    
