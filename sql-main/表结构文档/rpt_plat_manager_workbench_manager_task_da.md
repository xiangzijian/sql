序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	contract_code		
合同编号
string	否	C2		可空		否	否
2	contract_type		
合同类型 1-托管收房 2-托管出房
bigint	否	C2		可空		否	否
3	ctime		
创建时间
string	否	C2		可空		否	否
4	customer_name		
业主/租客姓名
string	否	C2		可空		否	否
5	customer_phone		
业主/租客手机号
string	否	C2		可空		否	否
6	deal_user_id		
处理人id
bigint	否	C2		可空		否	否
7	deal_user_name		
处理人姓名
string	否	C2		可空		否	否
8	downstream_code		
下游code
string	否	C2		可空		否	否
9	finish_time		
完成时间
string	否	C2		可空		否	否
10	house_address		
房源地址
string	否	C2		可空		否	否
11	house_code		
房源code
string	否	C2		可空		否	否
12	id		
主键
bigint	否	C2		可空		否	否
13	manager_user_id		
房管人id
bigint	否	C2		可空		否	否
14	manager_user_name		
房管人姓名
string	否	C2		可空		否	否
15	mtime		
更新时间
string	否	C2		可空		否	否
16	start_time		
开始时间(业务规定的开始时间)
string	否	C2		可空		否	否
17	status		
任务状态
bigint	否	C2		可空		否	否
18	task_id		
任务id
string	否	C2		可空		否	否
19	task_type		
任务类型 1-查验
bigint	否	C2		可空		否	否
20	upstream_code		
上游code
string	否	C2		可空		否	否
21	zuwu_user_id		
租务管家id
bigint	否	C2		可空		否	否
22	zuwu_user_name		
租务管家姓名
string	否	C2		可空		否	否
23	customer_phone_sha256		
业主租客手机号sha256
string	否	C2		可空		否	否
24	house_address_sha256		
实际借款人联系电话sha256
string	否	C2		可空		否	否
25	city_code		
城市code
string	否	C2		可空		否	否
26	city_name		
城市名
string	否	C2		可空		否	否
27	delivery_date		
合同房屋交付日期
string	否	C2		可空		否	否
28	effective_start_date		
合同起租日
string	否	C2		可空		否	否
29	es_tag		
同步检索标识
bigint	否	C2		可空		否	否
30	sign_date		
合同签约日期
string	否	C2		可空		否	否
31	biz_type		
业务类型，1签约，2解约
bigint	否	C2		可空		否	否
32	pt		
分区字段
string	否	C2		可空		否	是
33	completer_id		
完成人id
bigint	否	C2		可空		否	否
34	completer_name		
完成人姓名
string	否	C2		可空		否	否
35	plan_into_date		
计划入住时间
string	否	C2		可空		否	否
36	expire_time		
到期时间
string	否	C2		可空		否	否
37	plan_into_date_first		
计划入住日首次填写时间
string	否	C2		可空		否	否
38	plan_into_date_new		
计划入住日最新修改时间
string	否	C2		可空		否	否
39	task_define_id		
自定义任务类型
string	否	C2		可空		否	否
40	emergency_state		
紧急状态
10:紧急,20:非常紧急
string	否	C2		可空		否	否
41	appoint_time		
预约时间
string	否	C2		可空		否	否
42	manager_user_comp_code		
房管公司编号
string	否	C2		可空		否	否
