序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	order_id		
订单id
bigint	否	C2		可空		否	否
2	order_no		
订单编码
string	否	C2		可空		否	否
3	service_order_code		
服务单code
string	否	C2		可空		否	否
4	item_code		
服务项编码
string	否	C2		可空		否	否
5	item_name		
服务项名称
string	否	C2		可空		否	否
6	commodity_code		
商品编码
string	否	C2		可空		否	否
7	commodity_name		
商品名称
string	否	C2		可空		否	否
8	amount		
数量
decimal(20,2)	否	C2		可空		否	否
9	unit		
单位
string	否	C2		可空		否	否
10	unit_price		
单价
decimal(20,2)	否	C2		可空		否	否
11	spec		
规格
string	否	C2		可空		否	否
12	cost		
总额
decimal(20,2)	否	C2		可空		否	否
13	commodity_type		
商品类型
1:下单商品,2:实际商品
bigint	否	C2		可空		否	否
14	item_type		
项目类型
bigint	否	C2		可空		否	否
15	create_ucid		
创建人ucid
bigint	否	C2		可空		否	否
16	update_ucid		
修改人ucid
bigint	否	C2		可空		否	否
17	create_time		
创建时间
string	否	C2		可空		否	否
18	update_time		
修改时间
string	否	C2		可空		否	否
19	measure_word		
量词，用于计价模板的商品
decimal(20,2)	否	C2		可空		否	否
20	unique_key		
重复商品唯一数据标识
string	否	C2		可空		否	否
21	function_name_id		
功能间id
bigint	否	C2		可空		否	否
22	function_name		
功能间
string	否	C2		可空		否	否
23	fault_desc		
故障描述
string	否	C2		可空		否	否
24	fault_list		
故障列表
string	否	C2		可空		否	否
25	pt		
分区字段
string	否	C2		可空		否	是
26	property_code		
检修单编码
string	否	C2		可空		否	否
27	house_resource_id		
托管房源编码
bigint	否	C2		可空		否	否
28	order_create_time		
订单创建时间
string	否	C2		可空		否	否
29	is_main_again		
是否30天重复维修
bigint	否	C2		可空		否	否
30	main_again_order_no		
重复维修订单编码
string	否	C2		可空		否	否
31	commodity_function		
商品+功能间
string	否	C2		可空		否	否
32	commodity_function_fault		
商品+功能间+故障
string	否	C2		可空		否	否
33	city_code		
城市编码
bigint	否	C2		可空		否	否
34	city_name		
城市名称
string	否	C2		可空		否	否
35	fault_desc_ext		
fault_desc拆出描述
string	否	C2		可空		否	否
36	order_type		
订单类型
4:委托保洁,5:市场保洁,6:公寓会员,7:搬家市场单,8:保洁周期卡,9:周期保洁,10:市场维修,11:洗衣储值卡,12:洗衣,13:保洁拼团券,14:微棠, 15:经纪人集采,16:轻托管维修单,17:用户集采,18:轻托管蓄客,19:保洁加单,20:轻托管美化,21:公寓酒店,22:小修订单,23:美租,24:美租装配, 25:美租装配,26:IOT门锁,27:省心租甲醛单,28:省心租宽带单
string	否	C2		可空		否	否
37	label_group		
订单标签一对多
1:检修,2:租金代扣,4:省心租自动下单,8:门锁工单,9:洽谈量房,10:装配,12:2.0订单,11:二手房门锁
string	否	C2		可空		否	否
38	main_again_order_create_time		
重复维修订单创建时间
string	否	C2		可空		否	否
39	main_again_service_order_complete_time		
重复维修服务单完工时间
string	否	C2		可空		否	否
40	main_again_service_order_professional_ucid		
重复维修服务单服务者ucid
bigint	否	C2		可空		否	否
41	main_again_days		
重复维修间隔天数
bigint	否	C2		可空		否	否
42	main_service_order_professional_name		
重复维修服务单服务者名称
string	否	C2		可空		否	否
43	service_order_status_code		
服务单状态编码
0:初始态,5:供应商已接单,10:待派单,20:待重新派单,30:待接单,40:待服务,50:服务中,60:服务挂起,65:待付款,70:已完成,80:已取消
bigint	否	C2		可空		否	否
44	id		
id
bigint	否	C2		可空		否	否
45	commodity_tag_name		
商品标签名称
string	否	C2		可空		否	否
46	commodity_level2_name		
商品二级品类
string	否	C2		可空		否	否
47	commodity_level3_name		
商品三级品类
string	否	C2		可空		否	否
48	manager_corp_code		
房管人公司编码
string	否	C2		可空		否	否
49	manager_corp_name		
房管人公司名称
string	否	C2		可空		否	否
