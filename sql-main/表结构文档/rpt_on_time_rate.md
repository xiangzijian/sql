-----------------------------------------------------
序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	pt		
分区字段
hive分区标识
string	否	C2		可空		否	是
2	create_month		
订单创建月份
string	否	C2		可空		否	否
3	order_create_time		
订单创建时间
string	否	C2		可空		否	否
4	city_name		
城市
string	否	C2		可空		否	否
5	bizcircle_name		
商圈
string	否	C2		可空		否	否
6	service_order_supplier_name		
供应商
string	否	C2		可空		否	否
7	service_order_professional_name		
服务者
string	否	C2		可空		否	否
8	service_order_professional_ucid		
服务者ID
string	否	C2		可空		否	否
9	order_no		
维修订单号
string	否	C2		可空		否	否
10	order_category		
订单分类
string	否	C2		可空		否	否
11	house_resource_id		
托管房源ID
string	否	C2		可空		否	否
12	performance_mode		
紧急单/普通单
string	否	C2		可空		否	否
13	service_order_complete_time		
完工时间
string	否	C2		可空		否	否
14	lease_start_date		
房源最新出租时间
string	否	C2		可空		否	否
15	service_start_time		
预约开始时间
string	否	C2		可空		否	否
16	label_group12		
租后维修/检修
string	否	C2		可空		否	否
17	order_status50		
是否取消
string	否	C2		可空		否	否
18	cancel_time		
取消时间
string	否	C2		可空		否	否
19	cancel_night		
是否夜间取消
string	否	C2		可空		否	否
20	cancel_daytime		
是否白天致电前取消
string	否	C2		可空		否	否
21	cancel_30m		
是否紧急单30分钟内取消
string	否	C2		可空		否	否
22	cancel_1h		
是否普通单1小时内取消
string	否	C2		可空		否	否
23	calltime_one		
首次致电时间
string	否	C2		可空		否	否
24	calltime_30m		
是否30分钟内致电
string	否	C2		可空		否	否
25	calltime_1h		
是否1小时内致电
string	否	C2		可空		否	否
26	assessment_time		
普通单及时上门考核时间
string	否	C2		可空		否	否
27	cancel_call1		
是否首次致电前取消
string	否	C2		可空		否	否
28	first_sign_time		
首次签到时间
string	否	C2		可空		否	否
29	time_null		
普通单上门时长
string	否	C2		可空		否	否
30	normal_is_sign_advance		
普通单是否及时上门
string	否	C2		可空		否	否
31	urgent_assessment_time		
紧急单考核时间
string	否	C2		可空		否	否
32	urgent_is_sign_advance		
紧急单是否2h上门
string	否	C2		可空		否	否
33	lease_task_complete		
租后是否及时完工
string	否	C2		可空		否	否
34	examine_task_complete		
检修是否及时完工
string	否	C2		可空		否	否
