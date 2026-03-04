序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	pt		
分区字段
hive分区标识
string	否	C2		可空		否	是
2	trusteeship_housedel_code		
托管房源编码
bigint	否	C2		可空		否	否
3	old_housedel_id		
普租房源编码
bigint	否	C2		可空		否	否
4	housedel_id		
出房中台房源编码
bigint	否	C2		可空		否	否
5	house_id		
房屋ID
bigint	否	C2		可空		否	否
6	contract_id		
收房合同id
bigint	否	C2		可空		否	否
7	contract_code		
收房合同编码
string	否	C2		可空		否	否
8	newid		
统计房源编码
string	否	C2		可空		否	否
9	resblock_id		
小区id
bigint	否	C2		可空		否	否
10	resblock_name		
小区名称
string	否	C2		可空		否	否
11	bizcircle_id		
商圈id
bigint	否	C2		可空		否	否
12	bizcircle_name		
商圈名称
string	否	C2		可空		否	否
13	district_code		
区域id
bigint	否	C2		可空		否	否
14	district_name		
区域名称
string	否	C2		可空		否	否
15	city_code		
城市编码
bigint	否	C2		可空		否	否
16	city_name		
城市名称
string	否	C2		可空		否	否
17	stat_city_name		
统计城市
string	否	C2		可空		否	否
18	protocol_type		
产品类型
string	否	C2		可空		否	否
19	house_area		
建筑面积
decimal(38,18)	否	C2		可空		否	否
20	bedroom_num		
卧室数量
bigint	否	C2		可空		否	否
21	del_create_time		
委托创建时间
string	否	C2		可空		否	否
22	old_housedel_typing_time		
原普租房源录入时间
string	否	C2		可空		否	否
23	rent_type		
租赁方式
bigint	否	C2		可空		否	否
24	sub_biz_type		
合同子类型
bigint	否	C2		可空		否	否
25	parent_contract_id		
原合同ID
bigint	否	C2		可空		否	否
26	contract_status_code		
合同状态编码
bigint	否	C2		可空		否	否
27	contract_status_name		
合同状态名称
string	否	C2		可空		否	否
28	contract_sign_time		
合同签约时间
string	否	C2		可空		否	否
29	contract_sign_date		
收房合同签约日期
string	否	C2		可空		否	否
30	effect_start_date		
协议生效开始日期
string	否	C2		可空		否	否
31	effect_end_date		
协议生效结束日期
string	否	C2		可空		否	否
32	extend_end_date		
延长期结束日期
string	否	C2		可空		否	否
33	extend_days		
协议扩展天数
bigint	否	C2		可空		否	否
34	sign_days		
签约天数
bigint	否	C2		可空		否	否
35	terminate_reason		
解约原因
string	否	C2		可空		否	否
36	terminate_time		
解约时间
string	否	C2		可空		否	否
37	terminate_date		
收房合同解约日期
string	否	C2		可空		否	否
38	terminate_sign_date		
解约签署日期
string	否	C2		可空		否	否
39	housein_back_date		
收房合同房屋返还日期
string	否	C2		可空		否	否
40	expected_profits1		
第一年收房价格
decimal(38,18)	否	C2		可空		否	否
41	rent_unit_code		
出租单元编码
bigint	否	C2		可空		否	否
42	rent_unit_status		
租赁状态
bigint	否	C2		可空		否	否
43	rent_unit_status_name		
租赁状态名称
string	否	C2		可空		否	否
44	current_house_status		
当前房屋状态
bigint	否	C2		可空		否	否
45	current_vacancy_day		
当前空置期天数
bigint	否	C2		可空		否	否
46	old_housedel_price		
原普租房源价格
decimal(38,18)	否	C2		可空		否	否
47	unit_guide_price		
挂牌价
decimal(38,18)	否	C2		可空		否	否
48	match_expected_profits		
匹配当前收房价格
当前收房基准价
decimal(38,18)	否	C2		可空		否	否
49	fund_company_code		
资管公司编码
string	否	C2		可空		否	否
50	fund_company_name		
资管公司名称
string	否	C2		可空		否	否
51	manager_corp_code		
管家公司编码
string	否	C2		可空		否	否
52	manager_corp_name		
管家公司名称
string	否	C2		可空		否	否
53	manager_region_code		
管家运营管理大区编码
string	否	C2		可空		否	否
54	manager_region_name		
管家运营管理大区/中心
string	否	C2		可空		否	否
55	manager_marketing_code		
管家运营大区编码
string	否	C2		可空		否	否
56	manager_marketing_name		
管家营销大区/部门
string	否	C2		可空		否	否
57	manager_area_code		
管家区域编码
string	否	C2		可空		否	否
58	manager_area_name		
管家区域/组
string	否	C2		可空		否	否
59	manager_shop_code		
管家门店编码
string	否	C2		可空		否	否
60	manager_shop_name		
管家门店
string	否	C2		可空		否	否
61	manager_team_code		
管家店组编码
string	否	C2		可空		否	否
62	manager_team_name		
管家店组
string	否	C2		可空		否	否
63	manager_ucid		
房管ucid
bigint	否	C2		可空		否	否
64	manager_no		
管家系统号
bigint	否	C2		可空		否	否
65	manager_name		
管家姓名
string	否	C2		可空		否	否
66	sign_region_code		
签约人签约时运营管理大区/中心编码
string	否	C2		可空		否	否
67	sign_region_name		
签约人签约时运营管理大区/中心
string	否	C2		可空		否	否
68	sign_marketing_code		
签约人签约时营销大区/部门编码
string	否	C2		可空		否	否
69	sign_marketing_name		
签约人签约时营销大区/部门
string	否	C2		可空		否	否
70	sign_area_code		
签约人签约时业务区域/组编码
string	否	C2		可空		否	否
71	sign_area_name		
签约人签约时业务区域/组
string	否	C2		可空		否	否
72	sign_shop_code		
签约人签约时门店编码
string	否	C2		可空		否	否
73	sign_shop_name		
签约人签约时门店
string	否	C2		可空		否	否
74	sign_team_code		
签约人签约时店组编码
string	否	C2		可空		否	否
75	sign_team_name		
签约人签约时店组
string	否	C2		可空		否	否
76	sign_ucid		
合同签约人ucid
bigint	否	C2		可空		否	否
77	sign_name		
合同签约员工姓名
string	否	C2		可空		否	否
78	sign_no		
合同签约员工系统号
bigint	否	C2		可空		否	否
79	rent_seeking_start_date		
招租开始日期
string	否	C2		可空		否	否
80	rent_seeking_end_date		
招租结束日期
string	否	C2		可空		否	否
81	rent_seeking_end_extend_date		
招租结束日期（含招租拓展期）
string	否	C2		可空		否	否
82	rent_seeking_expand_tag		
招租拓展标签
bigint	否	C2		可空		否	否
83	rent_seeking_expand_days		
招租拓展天数
bigint	否	C2		可空		否	否
84	second_rent_seeking_end_date		
二次招租结束日期
string	否	C2		可空		否	否
85	is_rent		
是否出租中
bigint	否	C2		可空		否	否
86	is_sign		
是否签约中
bigint	否	C2		可空		否	否
87	sign_rank		
第几个已签约状态的合同
bigint	否	C2		可空		否	否
88	presale_housedel_type		
二出库存房源类型
bigint	否	C2		可空		否	否
89	contract_censor_status		
收房合同审核状态
0审核中 1审核通过 2审核驳回 3待提审
bigint	否	C2		可空		否	否
90	if_direct_sale		
是否直营
bigint	否	C2		可空		否	否
91	if_0331_cukun		
是否0331库存在管
bigint	否	C2		可空		否	否
92	if_first_seek_expire_unhouseout		
是否当前首次招租已到期待出
bigint	否	C2		可空		否	否
93	if_0507erchu_seek_expire_unhouseout		
是否当前05/07二次招租已到期待出
bigint	否	C2		可空		否	否
94	hin_type		
已签约房源类型
1 0331库存签约在管 2 新增签约在管 3 已开始招租但未审核通过 4 未开始招租
bigint	否	C2		可空		否	否
95	if_meizu		
是否美租产品
bigint	否	C2		可空		否	否
96	decoration_start_date		
美租装修开始日期
string	否	C2		可空		否	否
97	decoration_order_code		
美租装修订单编码
string	否	C2		可空		否	否
98	if_preparation		
是否有整备期
bigint	否	C2		可空		否	否
99	preparation_start_date		
整备期开始日期
string	否	C2		可空		否	否
100	preparation_end_date		
整备期结束日期
string	否	C2		可空		否	否
101	process_rent_seeking_start_date		
加工后招租开始日期
string	否	C2		可空		否	否
