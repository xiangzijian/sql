序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	contract_id		
合同表id
bigint	否	C2		可空		否	否
2	contract_code		
合同编码
string	否	C2		可空		否	否
3	trusteeship_housedel_code		
托管房源编码
bigint	否	C2		可空		否	否
4	rent_type		
租赁方式 0:不限,1:整租,2:合租
bigint	否	C2		可空		否	否
5	rent_type_name		
租赁方式名称
string	否	C2		可空		否	否
6	customer_code		
客源编码
bigint	否	C2		可空		否	否
7	biz_type		
合同类型
bigint	否	C2		可空		否	否
8	sub_biz_type		
合同子类型 1:标准合同,2:续约合同
bigint	否	C2		可空		否	否
9	sub_biz_type_name		
合同子类型名称
string	否	C2		可空		否	否
10	contract_status_code		
合同状态编码
bigint	否	C2		可空		否	否
11	contract_status_name		
合同状态名称
string	否	C2		可空		否	否
12	agent_ucid		
出房经纪人(标准合同)
bigint	否	C2		可空		否	否
13	agent_no		
出房经纪人系统号(标准合同)
bigint	否	C2		可空		否	否
14	agent_name		
出房经纪人姓名(标准合同)
string	否	C2		可空		否	否
15	contract_create_time		
合同创建时间
string	否	C2		可空		否	否
16	city_code		
合同城市编码
bigint	否	C2		可空		否	否
17	city_name		
合同城市名称
string	否	C2		可空		否	否
18	org_code		
合同组织编码
string	否	C2		可空		否	否
19	rent_unit_code		
出租单元编码
关联带看
bigint	否	C2		可空		否	否
20	sign_date		
合同签署日期
string	否	C2		可空		否	否
21	effect_start_date		
协议生效开始日期
string	否	C2		可空		否	否
22	effect_end_date		
协议生效结束日期
string	否	C2		可空		否	否
23	delivery_date		
房屋交付日期
string	否	C2		可空		否	否
24	sign_months		
签约月数
decimal(20,2)	否	C2		可空		否	否
25	sign_days		
签约天数(实际)
bigint	否	C2		可空		否	否
26	sign_price		
签约价格 月租金
decimal(20,2)	否	C2		可空		否	否
27	pay_period		
支付周期 20:出房月付,21:出房季付,22:出房半年付,23:出房年付
bigint	否	C2		可空		否	否
28	first_pay_date		
第一次付款日期
string	否	C2		可空		否	否
29	deposit		
押金
decimal(20,2)	否	C2		可空		否	否
30	service_charge		
佣金
佣金有为0的情况（没收佣金） 可以看服务费比例 字段
decimal(20,2)	否	C2		可空		否	否
31	revoke_type		
解约类型
1:到期解约,2:租客违约,3:公司违约,4:业主违约,5:超时未付款,6:协议错签,7:终止寻租,8:单方解约-熔断解约,9:单方解约-逾期交房,10:其他
bigint	否	C2		可空		否	否
32	back_date		
房屋归还时间
string	否	C2		可空		否	否
33	revoke_amt		
违约金
小于0 公司收款 ; 大于0 公司付款 (直接去得合同系统数据,没做二次加工)
decimal(20,2)	否	C2		可空		否	否
34	revoke_reason		
违约原因
string	否	C2		可空		否	否
35	termination_time		
解约时间
string	否	C2		可空		否	否
36	broker_company_code		
经纪公司编码
string	否	C2		可空		否	否
37	broker_company_name		
经纪公司名称
string	否	C2		可空		否	否
38	fund_company_code		
资管公司编码
string	否	C2		可空		否	否
39	fund_company_name		
资管公司名称
string	否	C2		可空		否	否
40	manager_no		
房管系统号
bigint	否	C2		可空		否	否
41	manager_name		
房管名称
string	否	C2		可空		否	否
42	manager_ucid		
房管ucid
bigint	否	C2		可空		否	否
43	manager_shop_name		
门店
string	否	C2		可空		否	否
44	manager_area_name		
业务区域/组
string	否	C2		可空		否	否
45	manager_marketing_name		
营销大区/部门
string	否	C2		可空		否	否
46	manager_region_name		
运营管理大区/中心
string	否	C2		可空		否	否
47	housedel_id		
房源id
关联商机
bigint	否	C2		可空		否	否
48	termination_contract_id		
解约合同id
bigint	否	C2		可空		否	否
49	termination_contract_no		
解约合同编码
string	否	C2		可空		否	否
50	pt		
分区字段
string	否	C2		可空		否	是
51	housein_contract_id		
收房合同id
bigint	否	C2		可空		否	否
52	housein_contract_code		
收房合同编码
string	否	C2		可空		否	否
53	housein_effect_start_date		
收房合同有效开始日期
string	否	C2		可空		否	否
54	housein_effect_end_date		
收房合同有效结束日期
string	否	C2		可空		否	否
55	parent_contract_id		
父合同id
bigint	否	C2		可空		否	否
56	corp_code		
出房人成交公司编码
string	否	C2		可空		否	否
57	corp_name		
出房人成交公司名称
string	否	C2		可空		否	否
58	marketing_code		
出房人成交营销大区/部门
string	否	C2		可空		否	否
59	marketing_name		
出房人成交营销大区/部门
string	否	C2		可空		否	否
60	area_code		
出房人成交业务区域/组
string	否	C2		可空		否	否
61	area_name		
出房人成交业务区域/组
string	否	C2		可空		否	否
62	shop_code		
出房人成交门店
string	否	C2		可空		否	否
63	shop_name		
出房人成交门店
string	否	C2		可空		否	否
64	team_code		
出房人成交店组
string	否	C2		可空		否	否
65	team_name		
出房人成交店组
string	否	C2		可空		否	否
66	brand_code		
出房人成交品牌编码
bigint	否	C2		可空		否	否
67	brand_name		
出房人成交品牌编码
string	否	C2		可空		否	否
68	contract_sign_time		
合同签约时间
string	否	C2		可空		否	否
69	cust_ucid		
客户ucid
获取签约客源的维护时间最新的客户ucid，与合同签约时手机号无关，使用时候请慎用
bigint	否	C2		可空		否	否
70	cust_phone_encrypt		
(无法解密)客户手机号加密
string	否	C2		可空		否	否
71	is_sign_online		
是否在线签约
bigint	否	C2		可空		否	否
72	c_housedel_id		
C端房源编码
string	否	C2		可空		否	否
73	is_renewal		
是否有续约合同
此合同后续有没有续签合同
bigint	否	C2		可空		否	否
74	resblock_id		
小区id
bigint	否	C2		可空		否	否
75	resblock_name		
小区名称
string	否	C2		可空		否	否
76	bizcircle_id		
商圈id
bigint	否	C2		可空		否	否
77	bizcircle_name		
商圈名称
string	否	C2		可空		否	否
78	guohu_receivable_commission		
出房抽佣应收
decimal(20,2)	否	C2		可空		否	否
79	zhongjie_receivable_commission		
出房分佣应收
decimal(20,2)	否	C2		可空		否	否
80	guohu_paid_commission		
出房抽佣实收
抽补金额
decimal(20,2)	否	C2		可空		否	否
81	zhongjie_paid_commission		
出房分佣实收
decimal(20,2)	否	C2		可空		否	否
82	is_special_house		
是否特价房
bigint	否	C2		可空		否	否
83	special_house_reduce_amt		
特价房减免金额
decimal(20,2)	否	C2		可空		否	否
84	cust_manage_amt		
客户管理费
decimal(20,2)	否	C2		可空		否	否
85	cust_phone		
租客手机号
string	是	C2		可空		否	否
86	housein_delivery_date		
收房房屋交付日期
string	否	C2		可空		否	否
87	intention_status		
续约意向编码
1:未沟通,101:待确认,102:同意续约,103:无意向
bigint	否	C2		可空		否	否
88	intention_status_name		
续约意向
string	否	C2		可空		否	否
89	gov_report_status		
监管状态
0:未监管,1:监管报备中,2:已监管
bigint	否	C2		可空		否	否
90	houseout_rank		
第几次出房(标准合同)
bigint	否	C2		可空		否	否
91	manager_shop_code		
管家门店编码
string	否	C2		可空		否	否
92	manager_area_code		
管家业务区域/组
string	否	C2		可空		否	否
93	manager_marketing_code		
管家营销大区/部门编码
string	否	C2		可空		否	否
94	manager_region_code		
管家运营管理大区/中心编码
string	否	C2		可空		否	否
95	manager_corp_code		
管家公司编码
string	否	C2		可空		否	否
96	manager_corp_name		
管家公司
string	否	C2		可空		否	否
97	manager_team_code		
管家店组编码
string	否	C2		可空		否	否
98	manager_team_name		
管家店组
string	否	C2		可空		否	否
99	manager_func_code		
管家运营/职能/董事会编码
string	否	C2		可空		否	否
100	manager_func_name		
管家运营/职能/董事会
string	否	C2		可空		否	否
101	manager_brand_code		
管家品牌编码
string	否	C2		可空		否	否
102	manager_brand_name		
管家品牌
string	否	C2		可空		否	否
103	signmanager_ucid		
签约出房时管家ucid
bigint	否	C2		可空		否	否
104	signmanager_name		
签约出房时管家名称
string	否	C2		可空		否	否
105	signmanager_corp_code		
签约出房时管家公司编码
string	否	C2		可空		否	否
106	signmanager_corp_name		
签约出房时管家公司名称
string	否	C2		可空		否	否
107	signmanager_marketing_code		
签约出房时管家管家营销大区/部门编码
string	否	C2		可空		否	否
108	signmanager_marketing_name		
签约出房时管家管家营销大区/部门
string	否	C2		可空		否	否
109	signmanager_area_code		
签约出房时管家业务区域/组编码
string	否	C2		可空		否	否
110	signmanager_area_name		
签约出房时管家业务区域/组
string	否	C2		可空		否	否
111	signmanager_shop_code		
签约出房时管家门店编码
string	否	C2		可空		否	否
112	signmanager_shop_name		
签约出房时管家门店名称
string	否	C2		可空		否	否
113	signmanager_team_code		
签约出房时管家店组编码
string	否	C2		可空		否	否
114	signmanager_team_name		
签约出房时管家店组名称
string	否	C2		可空		否	否
115	signmanager_brand_code		
签约出房时管家品牌编码
string	否	C2		可空		否	否
116	signmanager_brand_name		
签约出房时管家品牌名称
string	否	C2		可空		否	否
117	termination_contract_create_time		
合同解约创建时间
string	否	C2		可空		否	否
118	customer_service_fee_rate		
服务费比例%
decimal(20,2)	否	C2		可空		否	否
119	second_out		
二出房状态
0:不是二出房,1:二出房
bigint	否	C2		可空		否	否
120	is_advance_sign		
是否提前签约
bigint	否	C2		可空		否	否
121	receivable_agency_fee		
应收中介费
decimal(20,2)	否	C2		可空		否	否
122	paid_agency_fee		
实收中介费
decimal(20,2)	否	C2		可空		否	否
123	next_valid_contract_code		
下一个有效合同编码
城市在用明细时候，统计解约量，还会和已签约的做匹配判断是否是因为错签等，导致解约量统计多了，有了这个字段，就可以剔除这类解约，比如，A合同签错了，又重新签了B合同，在统计解约量的时候，解约量会统计1，实际并没有解约
string	否	C2		可空		否	否
124	housein_sub_contract_code		
收房子合同编码
string	否	C2		可空		否	否
125	service_reduce_amt		
服务费减免金额
decimal(20,2)	否	C2		可空		否	否
126	marketing_type		
作废
作废
string	否	C2		可空		否	否
127	is_valid		
是否有效
房屋返回日期<合同开始日期
bigint	否	C2		可空		否	否
128	fund_company_type		
资管公司类型
直营:直营,非直营:非直营
string	否	C2		可空		否	否
129	cust_registration		
租客户籍
string	否	C2		可空		否	否
130	cust_name		
租客名称
string	是	C2		可空		否	否
131	cust_cert_type		
租客证件类型
1:身份证,2:户口本,3:台胞证,4:社保卡,5:驾驶证,6:护照,7:军官证,8:居住证,9:营业执照,10:执业许可证,11:事业单位法人证书,12:组织机构代码证,13:港澳通行证,14:统一社会信用代码
bigint	否	C2		可空		否	否
132	cust_cert_no		
租客证件号码
string	是	C2		可空		否	否
133	termination_contract_signed_time		
解约合同签约时间
string	否	C2		可空		否	否
134	custdel_name		
客源名称
string	否	C2		可空		否	否
135	agent_type		
经纪人类型
-911:无,0:普通经纪人,1:客户经理,2:精英经纪人,3:省心租专岗经纪人
bigint	否	C2		可空		否	否
136	is_add_qwx		
客户是否添加企业微信
bigint	否	C2		可空		否	否
137	qwx_add_date		
企业微信添加日期
string	否	C2		可空		否	否
138	func_code		
出房人成交运营/职能/董事会编码
string	否	C2		可空		否	否
139	func_name		
出房人成交运营/职能/董事会
string	否	C2		可空		否	否
140	region_code		
出房人成交运营管理大区/中心编码
string	否	C2		可空		否	否
141	region_name		
出房人成交运营管理大区/中心
string	否	C2		可空		否	否
142	signmanager_func_code		
签约出房时管家运营/职能/董事会编码
string	否	C2		可空		否	否
143	signmanager_func_name		
签约出房时管家运营/职能/董事会
string	否	C2		可空		否	否
144	signmanager_region_code		
签约出房时管家运营管理大区/中心编码
string	否	C2		可空		否	否
145	signmanager_region_name		
签约出房时管家运营管理大区/中心
string	否	C2		可空		否	否
146	signmanager_no		
签约时管家系统号
bigint	否	C2		可空		否	否
147	sell_type		
去化类型
1:续约,2:临期预售,3:违约预售,4:常规去化
bigint	否	C2		可空		否	否
148	next_valid_contract_sub_biz_type_name		
下一份合同类型
string	否	C2		可空		否	否
149	is_tail_sell		
是否尾房去化
出房合同开始日期距离收房合同结束日期＜365天 AND （无续约合同 OR 续约合同签署日期晚于出房合同开始日期）
bigint	否	C2		可空		否	否
150	contract_create_ucid		
合同创建人ucid
bigint	否	C2		可空		否	否
151	contract_create_job_name		
合同创建人岗位名称
string	否	C2		可空		否	否
152	expect_back_date		
预计还房日期
签了退租确认协议的才会有值
string	否	C2		可空		否	否
153	sys_expect_back_time		
系统预计还房时间
签约解约合同之前填写的时间
string	否	C2		可空		否	否
154	contract_product_type		
产品类型
10:省心租长租,20:省心租短租
bigint	否	C2		可空		否	否
155	short_rent_service_fee_ratio		
短租管理费比例
string	否	C2		可空		否	否
156	short_rent_service_fee_amt		
短租管理费金额
decimal(20,2)	否	C2		可空		否	否
157	building_name		
楼栋名称
string	否	C2		可空		否	否
158	is_upload_contattch		
是否上传合同附件
bigint	否	C2		可空		否	否
159	participant_type		
合同签署参与方类型
1:普通解约,2:单方解约
bigint	否	C2		可空		否	否
160	is_cust_agent_sign		
是否客户代理人签约
bigint	否	C2		可空		否	否
161	customer_service_fee_rate_list		
管理服务费比例
string	否	C2		可空		否	否
162	housein_protocol_type		
收房合同版式
产品类型
string	否	C2		可空		否	否
163	newterm_business_type		
解约业务类型
0:合同到期,1:租客违约,2:资管违约,16:协议错签
bigint	否	C2		可空		否	否
164	newterm_content		
解约文案内容
string	否	C2		可空		否	否
165	newterm_system_reason		
解约系统原因
string	否	C2		可空		否	否
166	cust_phone_ucid		
租户手机号注册ucid
string	否	C2		可空		否	否
167	contract_update_time		
合同更新时间
string	否	C2		可空		否	否
168	cust_cert_no_sha256		
租客证件号摘要
string	否	C2		可空		否	否
169	accounting_type		
核算方式
0:总额法,1:净额法
bigint	否	C2		可空		否	否
170	sub_brand_code		
出房人子品牌编码
string	否	C2		可空		否	否
171	sub_brand_name		
出房人子品牌名称
string	否	C2		可空		否	否
172	platform_mode_status		
平台模式
1:是,0:否
bigint	否	C2		可空		否	否
173	fixed_service_fee_rate		
固定服务费比例%
decimal(20,2)	否	C2		可空		否	否