序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	pt		
分区字段
hive分区标识
string	否	C2		可空		否	是
2	city_name		
城市名称
string	否	C2		可空		否	否
3	manager_corp_name		
管家公司
string	否	C2		可空		否	否
4	ticket_id		
服务管家工单id
string	否	C2		可空		否	否
5	contract_code		
合同号
string	否	C2		可空		否	否
6	ticket_source		
工单来源
0:自动创建,1:AI转人工
bigint	否	C2		可空		否	否
7	renter_union_id		
租客unionld
string	否	C2		可空		否	否
8	robot_id		
服务管家-机器人
string	否	C2		可空		否	否
9	advance_id		
服务管家-系统指派预处理人
bigint	否	C2		可空		否	否
10	ticket_status		
工单状态
1:待处理,2:待跟进,3:已解决,4:无法解决,5:无效建单,6:重复单
bigint	否	C2		可空		否	否
11	appeal_tag		
工单标签
2002:查询&取消&修改信息,2003:指定&更换服务者,2004:权益&使用咨询,2005:超时&时效不满意,2006:多次维修不满意,2007:服务态度不满意,2008:擅自改约&爽约&迟到,2009:客户超预期诉求,2010:表扬维修师傅,2011:其他,2101:水电燃,2102:物业&供暖费,2103:其他费用咨询,2201:租金支付咨询,2202:变更支付周期,2203:交租页面报错,2204:多交租金退回,2301:合同条款咨询,2302:租客续租,2303:换租&转租,2304:合同查询&解约&变更等问题,2401:联系不到管家,2402:更换管家,2403:投诉管家,2404:表扬管家,2501:报修&催单,2502:冻结&解冻,2503:临时密码&修改密码,2504:使用咨询,2601:下单&催单,2602:查询&取消&修改信息,2603:权益&使用咨询,2604:指定&更换服务者,2605:保洁不满意,2606:超服务范围,2607:表扬保洁,2701:甲醛问题,2702:人身伤害,2703:居住安全事件,2801:宽带-下单&催单,2802:宽带-使用咨询,2803:宽带-取消&验收,2804:宽带-查询&修改信息,2901:生活信息,2902:邻里纠纷问题&噪音,2903:房租开票/服务费开票,2904:居住证&租赁备案,2905:换租无忧咨询&申请,2906:其他
bigint	否	C2		可空		否	否
12	first_answer_time		
服务管家-首次响应时间
string	否	C2		可空		否	否
13	real_deal_id		
服务管家-实际处理人
bigint	否	C2		可空		否	否
14	real_deal_name		
实际处理人姓名
string	否	C2		可空		否	否
15	question_desc		
问题描述
string	否	C2		可空		否	否
16	deal_desc		
处理描述
string	否	C2		可空		否	否
17	feedback_id		
问题反馈人信息
bigint	否	C2		可空		否	否
18	close_time		
工单关闭时间
string	否	C2		可空		否	否
19	creater		
创建人
bigint	否	C2		可空		否	否
20	ctime		
创建时间
string	否	C2		可空		否	否
21	updator		
修改人
bigint	否	C2		可空		否	否
22	mtime		
更新时间
string	否	C2		可空		否	否
23	cloud_keeper_account_code		
云管家工号
string	否	C2		可空		否	否
24	cloud_keeper_real_code		
云管家真实ucid
string	否	C2		可空		否	否
25	evaluation_item		
满意度评价项
string	否	C2		可空		否	否
26	evaluation_level		
评价等级
1:很不满意,2:不满意,3:一般,4:满意,5:非常满意
bigint	否	C2		可空		否	否
27	evaluation_status		
评价状态
0:未评价,1:已评价,2:已失效
bigint	否	C2		可空		否	否
28	owner_union_id		
业主微信 union_id
string	否	C2		可空		否	否
29	remark		
评价备注
string	否	C2		可空		否	否
30	solved_status		
工单是否已解决
1:已解决,2:未解决
bigint	否	C2		可空		否	否
31	robot_user_code		
机器人企微号
bigint	否	C2		可空		否	否
32	real_code		
维护人ucid
bigint	否	C2		可空		否	否
33	union_id		
用户union_id
string	否	C2		可空		否	否
34	send_status		
发送状态
0:待发送,1:已发送,2:发送失败
bigint	否	C2		可空		否	否
35	manager_area_name		
业务区域/组
string	否	C2		可空		否	否
36	manager_marketing_name		
营销大区/部门
string	否	C2		可空		否	否
37	manager_region_name		
运营管理大区/中心
string	否	C2		可空		否	否
38	manager_shop_name		
门店
string	否	C2		可空		否	否
39	manager_no		
房管系统号
bigint	否	C2		可空		否	否
40	manager_name		
房管名称
string	否	C2		可空		否	否
41	cust_ucid		
客户ucid
bigint	否	C2		可空		否	否
42	housedel_id		
房源id
bigint	否	C2		可空		否	否
43	trusteeship_housedel_code		
托管房源编码
bigint	否	C2		可空		否	否
44	send_id		
评价自增id
string	否	C2		可空		否	否
45	employee_no		
企业微信机器人系统号
string	否	C2		可空		否	否
46	follow_type		
跟进类型
string	否	C2		可空		否	否
47	sinan_ticket_id		
司南工单Id
string	否	C2		可空		否	否
48	sinan		
是否司南工单
string	否	C2		可空		否	否
49	chat_type		
聊天类型
string	否	C2		可空		否	否
50	appeal_tag_cn		
工单诉求标签描述
string	否	C2		可空		否	否
51	parent_code		
一级分类code
bigint	否	C2		可空		否	否
52	parent_name		
一级标签name
string	否	C2		可空		否	否
53	group_id		
群聊id
string	否	C2		可空		否	否
54	three_current_code		
三级分类code
bigint	否	C2		可空		否	否
55	three_current_name		
三级分类name
string	否	C2		可空		否	否
56	b_send		
是否b端人员主动发起
1:b端人员发起聊天工单,2:非b端人员发起聊天工单
int	否	C2		可空		否	否
57	effect_start_date		
起租日
string	否	C2		可空		否	否
58	bizcircle_name		
商圈
string	否	C2		可空		否	否
59	resblock_name		
小区
string	否	C2		可空		否	否
60	mood		
情绪
string	否	C2		可空		否	否
61	view_count		
详情页打开次数
bigint	否	C2		可空		否	否
62	customer_nick_name		
租客昵称
string	否	C2		可空		否	否
63	notice_msg_time		
首次消息响应时间
不区分任何角色
string	否	C2		可空		否	否
64	cont_tag		
是否联系内部成员
资管，租务，否
string	否	C2		可空		否	否
65	mx_num_bad		
负向出现次数
bigint	否	C2		可空		否	否
66	sevenday_repeat		
是否48小时重复进线
限制工单二级分类相同
bigint	否	C2		可空		否	否
67	min_bad_time		
首次负向产生时间
string	否	C2		可空		否	否
68	ten_days_diff		
服务单生成后10天内产生客诉单量
bigint	否	C2		可空		否	否
69	kesu_ticket_id		
最近一次客诉单
string	否	C2		可空		否	否
70	kesu_create_time		
最近一次客诉单创建时间
string	否	C2		可空		否	否
71	time_diff_min		
最近的客诉单的时间差
bigint	否	C2		可空		否	否
72	all_time_notice		
全角色消息相应时长(min)
decimal(38,18)	否	C2		可空		否	否
73	service_time_notice		
服务管家消息相应时长(min)
decimal(38,18)	否	C2		可空		否	否
74	first_mood_min		
首次负向情绪产生距离服务单创建时间差(min)
decimal(38,18)	否	C2		可空		否	否
75	first_service_min		
首次负向情绪产生距离服务管家首次响应差(min)
decimal(38,18)	否	C2		可空		否	否
76	is_not_query		
租客是否质疑真人
string	否	C2		可空		否	否
77	query_type		
质疑类型
1:自动回复,2:ai,3:机器人,4:人工,5:真人
string	否	C2		可空		否	否
78	ctime_content_num		
首次负向情绪产生距离服务单创建时间的消息条数
bigint	否	C2		可空		否	否
79	answer_content_num		
首次负向情绪产生距离服务管家首次响应时间的消息条数
bigint	否	C2		可空		否	否
80	second_out_sn		
是否二出房
string	否	C2		可空		否	否
81	resblock_id		
小区id
bigint	否	C2		可空		否	否
82	sevendays_inter_mood		
负向单是否48小时内重复进线
限制工单二级分类相同
bigint	否	C2		可空		否	否
83	city_code		
城市编码
bigint	否	C2		可空		否	否
84	contract_sign_time		
签约时间
string	否	C2		可空		否	否
85	contract_status_name		
出房合同状态
string	否	C2		可空		否	否
86	ticket_type_company		
服务主体
string	否	C2		可空		否	否
87	session_id		
会话id
该工单的最早生成的sessionid
string	否	C2		可空		否	否
88	is_resp		
是否因服务不足负向
string	否	C2		可空		否	否
89	real_negative_reason		
服务不足负向原因
string	否	C2		可空		否	否
90	tag		
负向标签
string	否	C2		可空		否	否
91	self_work_ticket		
是否自闭环工单
string	否	C2		可空		否	否
92	participate_ticket		
参与方
string	否	C2		可空		否	否
93	ticket_ids_refresh_flag		
是否回溯负向
string	否	C2		可空		否	否
94	is_bit_pay		
是否小额赔付
string	否	C2		可空		否	否
95	bit_success_pay		
是否出款成功
string	否	C2		可空		否	否
96	alevel_ticket		
是否a级响应事件
string	否	C2		可空		否	否
97	brole_participate		
是否b端角色参与
b端角色为员工、微信外部联系人
string	否	C2		可空		否	否
