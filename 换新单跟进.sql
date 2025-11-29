select  house_code,contract_code,delivery_date,effective_start_date,`status`,t2.`item_data`,manager_user_name,manager_user_id,zuwu_user_name,zuwu_user_id,
t3.original_order_code,t3.commodity_name,t3.no_maintain_reason_desc
 from (select * from rpt_plat_manager_workbench_manager_task_da where pt='${-1d_pt}' and task_define_id = '447' ) t1
 left join (select * from dw_plat_lease_property_property_delivery_detail_da where pt='${-1d_pt}') t2
 on t1.downstream_code = t2.property_code
 left join (select * from ods.ods_plat_beijia_transaction_trade_order_replace_info_da ) t3
 on t1.task_id = t3.task_id