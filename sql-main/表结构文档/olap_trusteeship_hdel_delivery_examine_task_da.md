# 表结构：olap_trusteeship_hdel_delivery_examine_task_da

## 表基本信息

- **数据库名**: `olap`
- **表名**: `olap_trusteeship_hdel_delivery_examine_task_da`
- **表说明**: 托管房源物业交割与检修任务表
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
合同编号
string	否	C2		可空		否	否
5	trusteeship_housedel_code		
托管房源编码
bigint	否	C2		可空		否	否
6	housedel_id		
房源id
bigint	否	C2		可空		否	否
7	houseinout_type		
合同类型 收房 出房
string	否	C2		可空		否	否
8	delivery_houseout_rank		
第几次出房 (出房用)
bigint	否	C2		可空		否	否
9	protocol_type		
产品类型
string	否	C2		可空		否	否
10	contract_sign_time		
合同签署时间
string	否	C2		可空		否	否
11	delivery_date		
合同交付时间
string	否	C2		可空		否	否
12	effect_start_date		
合同生效时间（起租生效）
string	否	C2		可空		否	否
13	effect_end_date		
合同生效时间（起租生效）
string	否	C2		可空		否	否
14	rent_seeking_start_date		
合同招租开始时间
string	否	C2		可空		否	否
15	back_date		
合同还房日期
string	否	C2		可空		否	否
16	term_contract_auth_apply_time		
发起解约申请时间
string	否	C2		可空		否	否
17	terminate_contract_create_time		
解约合同创建时间
string	否	C2		可空		否	否
18	terminate_contract_sign_time		
解约合同签约时间
string	否	C2		可空		否	否
19	terminate_time		
解约时间
string	否	C2		可空		否	否
20	contract_status_code		
合同状态编码
bigint	否	C2		可空		否	否
21	contract_status_name		
合同状态名称
string	否	C2		可空		否	否
22	manager_corp_code		
资管公司编码
string	否	C2		可空		否	否
23	manager_corp_name		
资管公司名称
string	否	C2		可空		否	否
24	manager_func_code		
资管运营/职能/董事会编码
string	否	C2		可空		否	否
25	manager_func_name		
资管运营/职能/董事会
string	否	C2		可空		否	否
26	manager_region_code		
资管运营管理大区/中心编码
string	否	C2		可空		否	否
27	manager_region_name		
资管运营管理大区/中心
string	否	C2		可空		否	否
28	manager_marketing_code		
资管营销大区/部门编码
string	否	C2		可空		否	否
29	manager_marketing_name		
资管营销大区/部门
string	否	C2		可空		否	否
30	manager_area_code		
资管业务区域/组
string	否	C2		可空		否	否
31	manager_area_name		
资管业务区域/组
string	否	C2		可空		否	否
32	manager_shop_code		
资管门店编码
string	否	C2		可空		否	否
33	manager_shop_name		
资管门店
string	否	C2		可空		否	否
34	manager_team_code		
资管店组编码
string	否	C2		可空		否	否
35	manager_team_name		
资管店组
string	否	C2		可空		否	否
36	manager_no		
资管系统号
bigint	否	C2		可空		否	否
37	manager_ucid		
资管ucid
bigint	否	C2		可空		否	否
38	manager_name		
资管姓名
string	否	C2		可空		否	否
39	fund_company_code		
资管公司编码
string	否	C2		可空		否	否
40	fund_company_name		
资管公司名称
string	否	C2		可空		否	否
41	fund_company_type		
资管公司类型 直营 非直营
string	否	C2		可空		否	否
42	is_task_time		
是否达到做任务时间
bigint	否	C2		可空		否	否
43	task_id		
任务id
bigint	否	C2		可空		否	否
44	task_type		
任务类型 物业交割 检修 复检 物品盘点 标准交房
string	否	C2		可空		否	否
45	task_status		
任务状态 2待处理 3跟进中 4已完结 5已取消
bigint	否	C2		可空		否	否
46	biz_type		
场景类型 1签约 2解约
bigint	否	C2		可空		否	否
47	deal_employee_str		
当时处理人list
string	否	C2		可空		否	否
48	deal_is_housekeeper		
当时处理人是否是租务管家
bigint	否	C2		可空		否	否
49	housekeeper_ucid		
租务管家ucid
当时
bigint	否	C2		可空		否	否
50	current_deal_employee_ucid		
当前处理人ucid
bigint	否	C2		可空		否	否
51	current_deal_employee_name		
当前处理人姓名
string	否	C2		可空		否	否
52	current_deal_employee_job_name		
当前处理人岗位
string	否	C2		可空		否	否
53	task_create_time		
任务创建时间
string	否	C2		可空		否	否
54	task_follow_time		
任务跟进时间
string	否	C2		可空		否	否
55	task_finish_time		
任务完成时间
string	否	C2		可空		否	否
56	task_cancel_time		
任务取消时间
string	否	C2		可空		否	否
57	property_code		
检修单&交割单编码
string	否	C2		可空		否	否
58	property_status		
检修单&交割单状态 1待创建 2 已提交 3 已确认 4 审核通过 5 审核不通过
bigint	否	C2		可空		否	否
59	property_style_type		
样式类型 1-纸质版 2-电子版
bigint	否	C2		可空		否	否
60	property_create_time		
检修单&交割单创建时间
string	否	C2		可空		否	否
61	property_submit_time		
检修单&交割单提交时间
string	否	C2		可空		否	否
62	property_checked_time		
检修单&交割单审核完成时间
string	否	C2		可空		否	否
63	property_confirm_time		
检修单&交割单确认时间
string	否	C2		可空		否	否
64	is_ontime		
是否及时完成
bigint	否	C2		可空		否	否
65	property_employee_ucid		
检修单&交割单处理人ucid
bigint	否	C2		可空		否	否
66	property_employee_name		
检修单&交割单处理人ucid
string	否	C2		可空		否	否
67	property_corp_code		
检修单&交割单处理人公司编码
string	否	C2		可空		否	否
68	property_corp_name		
检修单&交割单处理人公司名称
string	否	C2		可空		否	否
69	property_func_code		
检修单&交割单处理人运营/职能/董事会编码
string	否	C2		可空		否	否
70	property_func_name		
检修单&交割单处理人运营/职能/董事会
string	否	C2		可空		否	否
71	property_region_code		
检修单&交割单处理人运营管理大区/中心编码
string	否	C2		可空		否	否
72	property_region_name		
检修单&交割单处理人运营管理大区/中心
string	否	C2		可空		否	否
73	property_marketing_code		
检修单&交割单处理人营销大区/部门编码
string	否	C2		可空		否	否
74	property_marketing_name		
检修单&交割单处理人营销大区/部门
string	否	C2		可空		否	否
75	property_area_code		
检修单&交割单处理人业务区域/组
string	否	C2		可空		否	否
76	property_area_name		
检修单&交割单处理人业务区域/组
string	否	C2		可空		否	否
77	property_shop_code		
检修单&交割单处理人门店编码
string	否	C2		可空		否	否
78	property_shop_name		
检修单&交割单处理人门店
string	否	C2		可空		否	否
79	property_team_code		
检修单&交割单处理人店组编码
string	否	C2		可空		否	否
80	property_team_name		
检修单&交割单处理人店组
string	否	C2		可空		否	否
81	is_examine_order		
是否有检修家服订单
bigint	否	C2		可空		否	否
82	pt		
分区字段
string	否	C2		可空		否	是
83	property_position_name		
检修单&交割单处理人岗位名称
string	否	C2		可空		否	否
84	property_uc_job_name		
检修单&交割单处理人职务名称
string	否	C2		可空		否	否
85	task_time		
任务应做日期
string	否	C2		可空		否	否
86	resblock_id		
小区id
bigint	否	C2		可空		否	否
87	resblock_name		
小区名称
string	否	C2		可空		否	否
88	task_cancel_reason		
任务取消原因
string	否	C2		可空		否	否
89	rent_type		
租赁类型 0:不限,1:整租,2:分租 ,-1:未知
string	否	C2		可空		否	否
90	confirm_type		
确认类型
1:用户手动确认,2:超期系统自动确认,-911:无,-1:系统默认值
bigint	否	C2		可空		否	否
91	housekeeper_name		
租务管家
当时
string	否	C2		可空		否	否
92	current_deal1_employee_ucid		
当前处理人ucid（服务者）
bigint	否	C2		可空		否	否
93	current_deal1_employee_name		
当前处理人姓名（服务者）
string	否	C2		可空		否	否
94	task_workbench_flag		
任务平台标识
1:取消,2:延期
bigint	否	C2		可空		否	否
95	task_workbench_reason		
任务平台原因
string	否	C2		可空		否	否
96	change_fund_renewal		
是否跨主体公司续签
bigint	否	C2		可空		否	否
97	from_task_id		
上游来源任务id
bigint	否	C2		可空		否	否
98	auto_confirm_end_time		
自动确认时间
string	否	C2		可空		否	否
99	init_task_time		
原任务时间
string	否	C2		可空		否	否
100	deal_ucid		
当时处理人ucid
bigint	否	C2		可空		否	否
101	deal_name		
当时处理人
string	否	C2		可空		否	否
102	deal_supplier_name		
当时处理人的供应商
string	否	C2		可空		否	否
103	first_call_time		
首次预约电话拨打时间
标准交房
string	否	C2		可空		否	否
104	first_talk_time		
首次预约电话通话时长
标准交房
bigint	否	C2		可空		否	否
105	first_suc_call_time		
首次接通拨打时间
标准交房
string	否	C2		可空		否	否
106	first_suc_talk_time		
首次接通通话时长
标准交房
bigint	否	C2		可空		否	否
107	is_call_ontime		
是否及时预约
标准交房
bigint	否	C2		可空		否	否
108	housekeeper_corp_code		
租务管家公司编码
string	否	C2		可空		否	否
109	housekeeper_corp_name		
租务管家公司名称
string	否	C2		可空		否	否
110	housekeeper_func_code		
租务管家运营/职能/董事会编码
string	否	C2		可空		否	否
111	housekeeper_func_name		
租务管家运营/职能/董事会
string	否	C2		可空		否	否
112	housekeeper_region_code		
租务管家运营管理大区/中心编码
string	否	C2		可空		否	否
113	housekeeper_region_name		
租务管家运营管理大区/中心
string	否	C2		可空		否	否
114	housekeeper_marketing_code		
租务管家营销大区/部门编码
string	否	C2		可空		否	否
115	housekeeper_marketing_name		
租务管家营销大区/部门
string	否	C2		可空		否	否
116	housekeeper_area_code		
租务管家业务区域/组编码
string	否	C2		可空		否	否
117	housekeeper_area_name		
租务管家业务区域/组
string	否	C2		可空		否	否
118	preparation_start_date		
整备期开始日期
string	否	C2		可空		否	否
119	longest_suc_call_time		
最长接通拨打时间
标准交房
string	否	C2		可空		否	否
120	longest_suc_talk_time		
最长接通通话时长
标准交房
bigint	否	C2		可空		否	否
121	is_init_task_time		
是否到达原应做日期
bigint	否	C2		可空		否	否
122	platform_mode_status	olap_trusteeship_hdel_fund_company_da.platform_mode_status	
资管公司平台模式 1是 0否，-1未知，平台模式只用于加盟商
int	否	C2		可空		否	否
123	is_ka		
资管公司，是否KA模式，1是 0否，-1未知
tinyint	否	C2		可空		否	否
124	plan_into_date		
入住日期
出房签约场景 标准交房与物业交割用
string	否	C2		可空		否	否
125	first_op_into_time		
首次填写入住日期时间
出房签约场景 标准交房与物业交割用
string	否	C2		可空		否	否
126	intodate_is_ontime_typing		
是否及时填写入住日
bigint	否	C2		可空		否	否
127	housekeeper_shop_code		
租务管家门店编码
string	否	C2		可空		否	否
128	housekeeper_shop_name		
租务管家门店名称
string	否	C2		可空		否	否
129	housekeeper_team_code		
租务管家店组编码
string	否	C2		可空		否	否
130	housekeeper_team_name		
租务管家店组名称
string	否	C2		可空		否	否
