序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	id		
自增主键
bigint	否	C2		可空		否	否
2	lock_id		
锁唯一标识
string	否	C2		可空		否	否
3	manufacturer_code		
厂商code
string	否	C2		可空		否	否
4	trusteeship_housedel_code		
房源id
bigint	否	C2		可空		否	否
5	house_type		
房源类型 0-集中式 1-分散式
bigint	否	C2		可空		否	否
6	open_time		
开门时间
string	否	C2		可空		否	否
7	open_user_name		
开门用户名
string	否	C2		可空		否	否
8	open_user_phone		
开门用户手机号
string	否	C2		可空		否	否
9	open_user_type		
开门用户类型 1-签约人 2-同住人 3-管家
personType：用户类型，1-租客 2-同住人 3-管家（废弃） 4-业主 9-资管经理 10-客户经理 11-经济人 12-租务管家 13-服务者
bigint	否	C2		可空		否	否
10	open_user_ucid		
开门用户ucid
bigint	否	C2		可空		否	否
11	open_way		
开门方式
0-未知 1-蓝牙 2-长效密码 3-临时密码 4-长效密码正确并开门 5-临时密码正确并开门 6-内门把手开门 7-指纹 8-钥匙
bigint	否	C2		可空		否	否
12	open_user_phone_sha256		
开门用户手机号sha256
string	否	C2		可空		否	否
13	label_type		
标签类型0-普通1-带看
bigint	否	C2		可空		否	否
14	create_time		
创建时间
string	否	C2		可空		否	否
15	update_time		
更新时间
string	否	C2		可空		否	否
16	pt		
分区字段
string	否	C2		可空		否	是
17	fund_company_type		
资管公司类型
直营:直营,非直营:非直营
string	否	C2		可空		否	否
18	housein_contract_code		
收房合同编码
开门日期对应的收房合同编码
string	否	C2		可空		否	否
19	houseout_contract_code		
出房合同编码
开门日期对应的出房合同编码
string	否	C2		可空		否	否
20	first_housein_contract_code		
首次收房合同编码
房源首次收房合同
string	否	C2		可空		否	否
21	last_housein_contract_code		
最近收房合同编码
string	否	C2		可空		否	否
22	houseout_effect_start_date		
出房合同开始日期
string	否	C2		可空		否	否
23	houseout_effect_end_date		
出房合同结束日期
string	否	C2		可空		否	否
24	city_code		
城市编码
string	否	C2		可空		否	否
25	city_name		
城市名称
string	否	C2		可空		否	否
26	district_code		
城区编码
string	否	C2		可空		否	否
27	district_name		
城区名称
string	否	C2		可空		否	否
28	room_cnt		
居室数
int	否	C2		可空		否	否
29	fail_reason		
0-成功，1-获取秘钥失败，2-蓝牙链接失败，3-解析秘钥失败-1-连接超时
0-成功，1-获取秘钥失败，2-蓝牙链接失败，3-解析秘钥失败-1-连接超时
bigint	否	C2		可空		否	否
30	manager_marketing_code		
管家运营大区编码
string	否	C2		可空		否	否
31	manager_marketing_name		
营销大区/部门
string	否	C2		可空		否	否
32	manager_area_code		
管家区域编码
string	否	C2		可空		否	否
33	manager_area_name		
业务区域/组
string	否	C2		可空		否	否
34	manager_ucid		
房管ucid
string	否	C2		可空		否	否
35	manager_name		
房管姓名
string	否	C2		可空		否	否
36	housein_effect_start_date		
收房协议生效开始日期
string	否	C2		可空		否	否
37	housein_effect_end_date		
收房协议生效结束日期
string	否	C2		可空		否	否
38	rent_seeking_start_date		
寻租开始日期
string	否	C2		可空		否	否
39	rent_seeking_end_date		
寻租结束日期
string	否	C2		可空		否	否
40	current_house_status		
当前房屋状态
1:当前已出租房,2:非首次待出租房,3:首次待出租房,4:业主委托完结房,5:当前已托管出房签约中,6:当前已托管未装配,7:其他
string	否	C2		可空		否	否
41	housein_contract_sign_time		
收房签约时间
string	否	C2		可空		否	否
42	houseout_contract_sign_time		
出房签约时间
string	否	C2		可空		否	否
43	houseout_delivery_date		
出房交付日期
string	否	C2		可空		否	否
44	houseout_effect_start_date2		
最新出房协议生效开始日期
string	否	C2		可空		否	否
45	houseout_effect_end_date2		
最新出房协议生效结束日期
string	否	C2		可空		否	否
46	housein_contract_status_name		
收房合同状态
string	否	C2		可空		否	否
47	houseout_contract_status_name		
出房合同状态
string	否	C2		可空		否	否
48	house_period		
当前房源时机
作废
string	否	C2		可空		否	否
49	manager_corp_name		
资管公司名称
string	否	C2		可空		否	否
50	city_name_new		
新城市名称
string	否	C2		可空		否	否
51	open_hour		
开锁小时
string	否	C2		可空		否	否
52	open_house_period		
开锁时房源时机
string	否	C2		可空		否	否
53	password_id		
密码id
bigint	否	C2		可空		否	否
54	seq		
开门序列
bigint	否	C2		可空		否	否
55	reissue		
是否补发
bigint	否	C2		可空		否	否
56	open_success		
是否开门成功
bigint	否	C2		可空		否	否