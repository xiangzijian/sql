--模板查询：资管跟进明细-12.1
select house_code AS `房源code`,
    contract_code AS `合同编号`,
    delivery_date AS `合同房屋交付日期`,
    effective_start_date AS `合同起租日`,
    `status`AS `任务状态`,
    t2.`item_data` AS `表单信息`,
    -- 解析 fieldDetailList 中的字段
    get_json_object(t2.item_data, '$.itemList[0].innerDetailList[0].fieldDetailList[0].value') AS `是否同意客户诉求`,
    get_json_object(t2.item_data, '$.itemList[0].innerDetailList[0].fieldDetailList[1].value') AS `机器是否为全新`,
    get_json_object(t2.item_data, '$.itemList[0].innerDetailList[0].fieldDetailList[2].value') AS `费用承担方`,
    get_json_object(t2.item_data, '$.itemList[0].innerDetailList[0].fieldDetailList[3].value') AS `购买渠道`,
    get_json_object(t2.item_data, '$.itemList[0].innerDetailList[0].fieldDetailList[4].value') AS `物流单号`,
    get_json_object(t2.item_data, '$.itemList[0].innerDetailList[0].fieldDetailList[5].value') AS `上传购买凭证`,
    get_json_object(t2.item_data, '$.itemList[0].innerDetailList[0].fieldDetailList[6].value') AS `租客是否认同最终处理结果`,
    get_json_object(t2.item_data, '$.itemList[0].innerDetailList[0].fieldDetailList[7].value') AS `上传沟通截图`,
    manager_user_name AS `资管`,
    manager_user_id AS `资管工号`,
    zuwu_user_name AS `租务`,
    zuwu_user_id AS `租务工号`,
    t3.original_order_code AS `原订单编码`,
    t3.commodity_name AS `商品名称`,
    t4.order_create_time AS `订单创建时间`,
    t4.first_sign_time AS `首次签到时间`,
	t3.replace_order_code AS `换新单编码`,
    t3.create_time AS `换新单创建时间`,
    t1.finish_time AS `换新单完成时间`,
    t3.no_maintain_reason_desc AS `暂不维修原因`,
    t5.service_order_professional_name AS `供应商`,
	t5.service_order_professional_name AS `服务者`,
	t5.service_order_professional_ucid AS `服务Id`,
    t4.last_suspend_remark AS `挂起原因`,-- 选择“node_type=1”
    case when t6.order_no is not null  then '是' else '否' end  AS `是否提交包外订单`,
    t6.update_time AS `包外订单创建时间`,
	t6.`type2Num` AS  `该包外单驳回次数`,
	t6.remark AS  `驳回理由`
from (
        select *
        from rpt.rpt_plat_manager_workbench_manager_task_da
        where pt = '20251129000000'
            and task_define_id IN( '447')
    ) t1
    left join (
         select property_code,
        max(item_data) as item_data
        from dw.dw_plat_lease_property_property_delivery_detail_da
        where pt = '20251129000000' group by property_code
    ) t2 on t1.downstream_code = t2.property_code
    left join (
        select task_id,
        max(replace_order_code) as replace_order_code,
        max(original_order_code) as original_order_code,
        max(commodity_name) as commodity_name,
        max(no_maintain_reason_desc) as no_maintain_reason_desc,
        max(create_time) as create_time   
        from ods.ods_plat_beijia_transaction_trade_order_replace_info_da
	  where pt = '20251129000000' 
      group by task_id
    ) t3 on t1.task_id = t3.task_id
    left join (
        select *
        from olap.olap_hj_fas_main_order_service_info_da
	  where pt = '20251129000000'
    ) t4 on t3.original_order_code = t4.order_no
    left join ( SELECT * FROM olap.olap_hj_fas_main_order_service_info_da WHERE pt = '20251129000000' ) t5
    on t3.original_order_code = t5.order_no
    left join (
        select order_no,min( case when node_type =1 then `update_time` end ) as `update_time`
	  ,count(DISTINCT case when operate_type =2 then `update_time` end) as `type2Num`,
	  collect_set(CAST(( case when operate_type =2 then `remark` end ) AS string))  as `remark`
        from olap.olap_hj_fas_main_order_service_out_free_repair_plan_bpm_log_da
        where pt = '20251130000000' GROUP by order_no
    ) t6 on t3.original_order_code = t6.order_no