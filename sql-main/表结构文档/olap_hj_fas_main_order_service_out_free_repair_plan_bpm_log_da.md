序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	city_code		
城市编码
bigint	否	C2		可空		否	否
2	city_name		
城市名称
string	否	C2		可空		否	否
3	bizcircle_id		
商圈id
bigint	否	C2		可空		否	否
4	bizcircle_name		
商圈名称
string	否	C2		可空		否	否
5	resblock_id		
楼盘id
bigint	否	C2		可空		否	否
6	resblock_name		
楼盘名称
string	否	C2		可空		否	否
7	manager_ucid		
资管ucid
bigint	否	C2		可空		否	否
8	manager_no		
资管系统号
bigint	否	C2		可空		否	否
9	manager_name		
资管名称
string	否	C2		可空		否	否
10	manager_corp_code		
资管公司编码
string	否	C2		可空		否	否
11	manager_corp_name		
资管公司名称
string	否	C2		可空		否	否
12	manager_func_code		
资管运营/职能/董事会编码
string	否	C2		可空		否	否
13	manager_func_name		
资管运营/职能/董事会
string	否	C2		可空		否	否
14	manager_region_code		
资管运营管理大区/中心编码
string	否	C2		可空		否	否
15	manager_region_name		
资管 运营管理大区/中心
string	否	C2		可空		否	否
16	manager_marketing_code		
资管营销大区/部门编码
string	否	C2		可空		否	否
17	manager_marketing_name		
资管营销大区/部门
string	否	C2		可空		否	否
18	manager_area_code		
资管业务区域/组编码
string	否	C2		可空		否	否
19	manager_area_name		
资管业务区域/组
string	否	C2		可空		否	否
20	manager_shop_code		
资管门店编码
string	否	C2		可空		否	否
21	manager_shop_name		
资管门店
string	否	C2		可空		否	否
22	manager_team_code		
资管店组编码
string	否	C2		可空		否	否
23	manager_team_name		
资管店组
string	否	C2		可空		否	否
24	manager_brand_code		
资管品牌编码
string	否	C2		可空		否	否
25	manager_brand_name		
资管品牌
string	否	C2		可空		否	否
26	house_resource_id		
房源编码
bigint	否	C2		可空		否	否
27	label_group		
订单标签
1:检修,2:租金代扣,4:省心租自动下单,8:门锁工单,9:洽谈量房,10:装配,12:2.0订单,11:二手房门锁
bigint	否	C2		可空		否	否
28	order_type		
订单类型
4:委托保洁,5:市场保洁,6:公寓会员,7:搬家市场单,8:保洁周期卡,9:周期保洁,10:市场维修,11:洗衣储值卡,12:洗衣,13:保洁拼团券,14:微棠, 15:经纪人集采,16:轻托管维修单,17:用户集采,18:轻托管蓄客,19:保洁加单,20:轻托管美化,21:公寓酒店,22:小修订单,23:美租,24:美租装配, 25:美租装配,26:IOT门锁,27:省心租甲醛单,28:省心租宽带单
bigint	否	C2		可空		否	否
29	order_status		
订单状态
8:待报价,10:待平台派单,20:待供应商接单,21:待供应商派单,22:待服务者接单,23:待服务,24:服务中,30:待付款,40:订单完成,50:订单取消,11:成团中
bigint	否	C2		可空		否	否
30	service_order_code		
服务单编码
string	否	C2		可空		否	否
31	service_order_supplier_code		
服务单供应商编码
string	否	C2		可空		否	否
32	service_order_supplier_name		
服务单供应商
string	否	C2		可空		否	否
33	service_order_professional_name		
服务者名称
string	否	C2		可空		否	否
34	service_order_professional_ucid		
服务者ucid
bigint	否	C2		可空		否	否
35	plan_id		
包外计划id
bigint	否	C2		可空		否	否
36	log_id		
bpm id
bigint	否	C2		可空		否	否
37	node_type		
节点类型
1:服务者发起,2:调度发起,3:第一节点审批,4:第二节点审批,5:第三节点审批
bigint	否	C2		可空		否	否
38	operate_type		
操作类型
1:通过,2:驳回,3:撤回,4:无效,5:转办
bigint	否	C2		可空		否	否
39	bpm_form_data		
审批流表单信息
string	否	C2		可空		否	否
40	out_package_reason_type		
包外原因分类
1:包外维修范围,2:客户体验类包外维修,3:客业拒绝承担类包外维修,4:甲醛类包外维修,5:漏水类包外维修,6:风险事件类包外维修
bigint	否	C2		可空		否	否
41	remark		
备注
string	否	C2		可空		否	否
42	create_time		
创建时间
string	否	C2		可空		否	否
43	update_time		
更新时间
string	否	C2		可空		否	否
44	operator_ucid		
操作ucid
bigint	否	C2		可空		否	否
45	operator_name		
操作名称
string	否	C2		可空		否	否
46	operate_info		
操作信息
string	否	C2		可空		否	否
47	process_inst_id		
流程任务id
string	否	C2		可空		否	否
48	pt		
分区字段
string	否	C2		可空		否	是
49	order_no		
订单编码
string	否	C2		可空		否	否
50	deduction_performance_reason		
成本承担方
1:业主付费,2:租客付费,3:扣资管业绩,4:公司付费,5:品质承担-其他,6:资管付费,7:驳回,8:扣双倍业绩,9:额度包,10:品质承担-保障,11:扣区经业绩
bigint	否	C2		可空		否	否
51	out_package_reason_remark		
包外原因描述
string	否	C2		可空		否	否
52	out_package_dispute_code		
纠纷备案/客诉单号
string	否	C2		可空		否	否
53	total_amount		
总金额
decimal(20,2)	否	C2		可空		否	否
