
## 表基本信息

- **数据库名**: `olap`
- **表名**: `olap_trusteeship_hdel_examine_divide_da`
- **表说明**: 托管检修单归属表
- **更新日期**: [待更新]

---

## 字段信息



序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	city_code		
城市编码
bigint	否	C2		可空		否	否
2	city_name		
城市名称
string	否	C2		可空		否	否
3	contract_id		
合同id
bigint	否	C2		可空		否	否
4	contract_code		
合同编码
string	否	C2		可空		否	否
5	contract_status_name		
合同状态名称
string	否	C2		可空		否	否
6	renewal_contract_list		
续约合同列表
string	否	C2		可空		否	否
7	delivery_houseout_rank		
第几次出房（交付日期计算）
bigint	否	C2		可空		否	否
8	trusteeship_housedel_code		
托管房源编码
bigint	否	C2		可空		否	否
9	housedel_id		
房源id
bigint	否	C2		可空		否	否
10	sign_date		
合同签约日期
string	否	C2		可空		否	否
11	delivery_date		
合同交付日期
string	否	C2		可空		否	否
12	effect_start_date		
合同开始日期
string	否	C2		可空		否	否
13	effect_end_date		
合同结束日期(有续签用续约合同)
string	否	C2		可空		否	否
14	back_date		
还房日期(有续签用续约合同)
string	否	C2		可空		否	否
15	term_apply_time		
解约申请日期（首次）
string	否	C2		可空		否	否
16	housein_contract_sign_time		
收房合同签约时间
string	否	C2		可空		否	否
17	manager_corp_code		
资管公司编码
string	否	C2		可空		否	否
18	manager_corp_name		
资管公司名称
string	否	C2		可空		否	否
19	manager_func_code		
资管运营/职能/董事会编码
string	否	C2		可空		否	否
20	manager_func_name		
资管运营/职能/董事会
string	否	C2		可空		否	否
21	manager_region_code		
资管运营管理大区/中心编码
string	否	C2		可空		否	否
22	manager_region_name		
资管运营管理大区/中心
string	否	C2		可空		否	否
23	manager_marketing_code		
资管营销大区/部门编码
string	否	C2		可空		否	否
24	manager_marketing_name		
资管营销大区/部门
string	否	C2		可空		否	否
25	manager_area_code		
资管业务区域/组
string	否	C2		可空		否	否
26	manager_area_name		
资管业务区域/组
string	否	C2		可空		否	否
27	manager_shop_code		
资管门店编码
string	否	C2		可空		否	否
28	manager_shop_name		
资管门店
string	否	C2		可空		否	否
29	manager_team_code		
资管店组编码
string	否	C2		可空		否	否
30	manager_team_name		
资管店组
string	否	C2		可空		否	否
31	manager_no		
资管系统号
bigint	否	C2		可空		否	否
32	manager_ucid		
资管ucid
bigint	否	C2		可空		否	否
33	manager_name		
资管姓名
string	否	C2		可空		否	否
34	fund_company_code		
资管公司编码
string	否	C2		可空		否	否
35	fund_company_name		
资管公司名称
string	否	C2		可空		否	否
36	fund_company_type		
资管公司类型 直营 非直营
string	否	C2		可空		否	否
37	property_code		
检修单编码
string	否	C2		可空		否	否
38	property_create_time		
检修单创建时间
string	否	C2		可空		否	否
39	property_submit_time		
检修单提交时间
string	否	C2		可空		否	否
40	property_contract_type		
检修单合同类型 1-托管收房 2-托管出房
bigint	否	C2		可空		否	否
41	property_status		
检修单状态 1已确认 2 已提交 3 已确认 4 审核通过 5 审核不通过
bigint	否	C2		可空		否	否
42	property_employee_ucid		
检修单处理人ucid
bigint	否	C2		可空		否	否
43	task_id		
任务id
bigint	否	C2		可空		否	否
44	task_biz_type		
任务场景 1签约 2解约
bigint	否	C2		可空		否	否
45	order_code		
家服订单编码
string	否	C2		可空		否	否
46	order_status		
家服订单状态
string	否	C2		可空		否	否
47	order_creator_type		
家服订单创建人类型
string	否	C2		可空		否	否
48	order_create_ucid		
家服订单创建人ucid
bigint	否	C2		可空		否	否
49	order_create_time		
家服订单创建时间
string	否	C2		可空		否	否
50	order_finish_time		
家服订单完成时间
string	否	C2		可空		否	否
51	order_level1_name_list1		
家服订单一级类目名称
string	否	C2		可空		否	否
52	order_level2_name_list1		
家服订单二级类目名称
string	否	C2		可空		否	否
53	order_level3_name_list1		
家服订单三级类目名称
string	否	C2		可空		否	否
54	order_commodity_name		
家服订单商品
string	否	C2		可空		否	否
55	data_flag		
数据加工标识
string	否	C2		可空		否	否
56	pt		
分区字段
string	否	C2		可空		否	是
57	housekeeper_ucid		
租务管家ucid
bigint	否	C2		可空		否	否
58	housekeeper_name		
租务管家姓名
string	否	C2		可空		否	否
59	task_status		
任务状态
2待处理 3跟进中 4已完结 5已取消
bigint	否	C2		可空		否	否
60	task_finish_time		
任务完成时间
string	否	C2		可空		否	否
61	order_user_remark		
家服订单用户备注
string	否	C2		可空		否	否
62	order_platform_remark		
家服订单平台备注
string	否	C2		可空		否	否
63	is_effective_examine		
是否有效排查
bigint	否	C2		可空		否	否
64	is_effective_maintain		
是否有效维修
bigint	否	C2		可空		否	否
65	is_beforestart_finish_examine		
是否在起租日完成检修
bigint	否	C2		可空		否	否
66	commodity_code		
上架商品编码
string	否	C2		可空		否	否
67	service_name		
服务类型 维修 燃气
string	否	C2		可空		否	否
68	all_contract_list		
全部合同列表
string	否	C2		可空		否	否
69	unqualified_reason		
不合格原因
string	否	C2		可空		否	否
70	task_type		
任务类型
3:检修,12:复检
bigint	否	C2		可空		否	否
