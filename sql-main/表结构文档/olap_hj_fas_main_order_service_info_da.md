# 表结构：olap.olap_hj_fas_main_order_service_info_da

## 表基本信息

- **数据库名**: `olap`
- **表名**: `olap_hj_fas_main_order_service_info_da`
- **表说明**: 检修/维修主订单与服务单信息明细表（示例，可按实际调整）
- **更新日期**: [待更新]

---

## 字段信息（摘要）

> ⚠️ **说明**：原始文件为 Excel 导出的字段明细，此处仅整理常用/核心字段为 Markdown 表格，完整字段清单见下方“原始字段明细”。

| 序号 | 字段名 | 数据类型 | 是否允许NULL | 默认值 | 字段说明 |
|------|--------|----------|--------------|--------|----------|
| 1 | order_id | BIGINT | YES | NULL | 订单ID |
| 2 | order_no | STRING | YES | NULL | 订单号 |
| 3 | city_code | BIGINT | YES | NULL | 城市编码 |
| 4 | city_name | STRING | YES | NULL | 城市名称 |
| 5 | service_code | BIGINT | YES | NULL | 一级品类编码 |
| 6 | service_name | STRING | YES | NULL | 一级品类名称 |
| 7 | order_create_time | STRING | YES | NULL | 订单创建时间 |
| 8 | order_creator_ucid | BIGINT | YES | NULL | 创建人UCID |
| 9 | order_creator_type | BIGINT | YES | NULL | 创建人类型（0-云管家，1-C端，2-link经纪人，10001-整备管家） |
| 10 | order_creator_name | STRING | YES | NULL | 创建人姓名 |
| 11 | order_creator_corp_code | STRING | YES | NULL | 创建人公司编码 |
| 12 | order_creator_corp_name | STRING | YES | NULL | 创建人公司名称 |
| 13 | order_creator_func_code | STRING | YES | NULL | 创建人运营/职能/董事会编码 |
| 14 | order_creator_func_name | STRING | YES | NULL | 创建人运营/职能/董事会名称 |
| 15 | order_creator_region_code | STRING | YES | NULL | 创建人运营管理大区/中心编码 |
| 16 | order_creator_region_name | STRING | YES | NULL | 创建人运营管理大区/中心名称 |
| 17 | order_creator_marketing_code | STRING | YES | NULL | 创建人营销大区/部门编码 |
| 18 | order_creator_marketing_name | STRING | YES | NULL | 创建人营销大区/部门名称 |
| 19 | order_creator_area_code | STRING | YES | NULL | 创建人业务区域/组编码 |
| 20 | order_creator_area_name | STRING | YES | NULL | 创建人业务区域/组名称 |
| 21 | order_creator_shop_code | STRING | YES | NULL | 创建人门店编码 |
| 22 | order_creator_shop_name | STRING | YES | NULL | 创建人门店名称 |
| 23 | order_creator_team_code | STRING | YES | NULL | 创建人店组编码 |
| 24 | order_creator_team_name | STRING | YES | NULL | 创建人店组名称 |
| 25 | order_creator_brand_code | STRING | YES | NULL | 创建人品牌编码 |
| 26 | order_creator_brand_name | STRING | YES | NULL | 创建人品牌名称 |
| 27 | order_creator_mobile | STRING | YES | NULL | 下单人电话 |
| 28 | contact_user | STRING | YES | NULL | 联系人 |
| 29 | contact_user_mobile | STRING | YES | NULL | 联系人电话 |
| 30 | order_creator_mobile_encrypt | STRING | YES | NULL | 下单人电话（加密） |
| 31 | contact_user_mobile_encrypt | STRING | YES | NULL | 联系人电话（加密） |
| 32 | channel_code | STRING | YES | NULL | 渠道号 |
| 33 | channel_name | STRING | YES | NULL | 渠道名称 |
| 34 | order_status | BIGINT | YES | NULL | 订单状态（8待报价、10待平台派单、20待供应商接单…） |
| 35 | pay_type | BIGINT | YES | NULL | 支付方式（1线上、2线下、3无需 等） |
| 36 | pay_status | BIGINT | YES | NULL | 付款状态（10受理成功、20处理中、30成功 等） |
| 37 | pay_time | STRING | YES | NULL | 付款时间 |
| 38 | user_remark | STRING | YES | NULL | 用户备注 |
| 39 | platform_remark | STRING | YES | NULL | 平台备注 |
| 40 | platform_user_remark | STRING | YES | NULL | 云管家端用户备注 |
| 41 | resblock_id | BIGINT | YES | NULL | 小区ID |
| 42 | resblock_name | STRING | YES | NULL | 小区名称 |
| 43 | bizcircle_id | BIGINT | YES | NULL | 商圈ID |
| 44 | bizcircle_name | STRING | YES | NULL | 商圈名称 |
| 45 | urgent_flag | BIGINT | YES | NULL | 紧急单标识（0非紧急、1紧急、2紧急转非紧急） |
| 46 | label_group | STRING | YES | NULL | 订单标签组（一对多） |
| 47 | order_type | BIGINT | YES | NULL | 订单类型（4委托保洁、16轻托管维修单、22小修订单 等） |
| 48 | visible_to_tenant | BIGINT | YES | NULL | 对租客是否可见 |
| 49 | house_resource_id | BIGINT | YES | NULL | 托管房源编码 |
| 50 | lease_status | BIGINT | YES | NULL | 房屋出租状态（1未出租、2未入住、3已出租） |
| 51 | service_order_code | STRING | YES | NULL | 服务单编码 |
| 52 | service_order_status_code | BIGINT | YES | NULL | 服务单状态编码 |
| 53 | service_order_status_name | STRING | YES | NULL | 服务单状态名称 |
| 54 | service_order_supplier_code | BIGINT | YES | NULL | 供应商编码 |
| 55 | service_order_supplier_name | STRING | YES | NULL | 供应商名称 |
| 56 | parent_service_order_code | STRING | YES | NULL | 父服务单编号 |
| 57 | service_order_professional_mobile | STRING | YES | NULL | 服务者手机号 |
| 58 | service_order_professional_name | STRING | YES | NULL | 服务者姓名 |
| 59 | service_order_professional_ucid | BIGINT | YES | NULL | 服务者UCID |
| 60 | service_order_remark | STRING | YES | NULL | 服务单备注 |
| 61 | service_order_remark_time | STRING | YES | NULL | 服务单备注时间 |
| 62 | service_order_remark_name | STRING | YES | NULL | 服务单备注人 |
| 63 | service_order_professional_mobile_assist | STRING | YES | NULL | 服务者电话摘要 |
| 64 | service_order_professional_mobile_cipher | STRING | YES | NULL | 服务者电话加密 |
| 65 | pt | STRING | NO | NULL | 分区字段 |
| 66 | sign_state | BIGINT | YES | NULL | 签到异常标识 |
| 67 | service_order_complete_time | STRING | YES | NULL | 服务单完工时间 |
| 68 | order_complete_time | STRING | YES | NULL | 订单完单时间 |
| 69 | user_evaluation_star | BIGINT | YES | NULL | 用户评价星级 |
| 70 | user_evaluation_time | STRING | YES | NULL | 用户评价时间 |
| 71 | performance_mode | BIGINT | YES | NULL | 履约模式（0普通单、1紧急单、2加急单） |

> 如需补充更多字段，可参考下方“原始字段明细”继续补全表格。

---

## 分区信息

- **分区字段**: `pt` (STRING)
- **分区类型**: 按日期分区
- **分区格式**: `YYYY-MM-DD`（例如：`pt = '2025-01-20'`）

---

## 备注

- 此文档由原始 Excel 字段清单整理而来，若线上表结构有变更，请以 `DESC` / `SHOW CREATE TABLE olap.olap_hj_fas_main_order_service_info_da` 为准。

---

## 原始字段明细（保留原始导出格式）

```text
序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	order_id		
订单id
bigint	否	C2		可空		否	否
2	order_no		
订单号
string	否	C2		可空		否	否
3	city_code		
城市编码
bigint	否	C2		可空		否	否
4	city_name		
城市名称
string	否	C2		可空		否	否
5	service_code		
一级品类
bigint	否	C2		可空		否	否
6	service_name		
service_name
string	否	C2		可空		否	否
7	order_create_time		
创建时间
string	否	C2		可空		否	否
8	order_creator_ucid		
创建人ucid
bigint	否	C2		可空		否	否
9	order_creator_type		
创建人类型0-云管家 1-c端 2-link经纪人 10001-整备管家
bigint	否	C2		可空		否	否
10	order_creator_name		
创建人姓名
string	否	C2		可空		否	否
11	order_creator_corp_code		
创建人公司编码
string	否	C2		可空		否	否
12	order_creator_corp_name		
创建人公司名称
string	否	C2		可空		否	否
13	order_creator_func_code		
创建人运营/职能/董事会编码
string	否	C2		可空		否	否
14	order_creator_func_name		
创建人运营/职能/董事会
string	否	C2		可空		否	否
15	order_creator_region_code		
创建人运营管理大区/中心编码
string	否	C2		可空		否	否
16	order_creator_region_name		
创建人运营管理大区/中心
string	否	C2		可空		否	否
17	order_creator_marketing_code		
创建人营销大区/部门编码
string	否	C2		可空		否	否
18	order_creator_marketing_name		
创建人营销大区/部门
string	否	C2		可空		否	否
19	order_creator_area_code		
创建人业务区域/组编码
string	否	C2		可空		否	否
20	order_creator_area_name		
创建人业务区域/组
string	否	C2		可空		否	否
21	order_creator_shop_code		
创建人门店编码
string	否	C2		可空		否	否
22	order_creator_shop_name		
创建人门店
string	否	C2		可空		否	否
23	order_creator_team_code		
创建人店组编码
string	否	C2		可空		否	否
24	order_creator_team_name		
创建人店组
string	否	C2		可空		否	否
25	order_creator_brand_code		
创建人品牌编码
string	否	C2		可空		否	否
26	order_creator_brand_name		
创建人品牌
string	否	C2		可空		否	否
27	order_creator_mobile		
下单人电话
string	否	C2		可空		否	否
28	contact_user		
联系人
string	否	C2		可空		否	否
29	contact_user_mobile		
联系人电话
string	否	C2		可空		否	否
30	order_creator_mobile_encrypt		
下单人电话加密
string	否	C2		可空		否	否
31	contact_user_mobile_encrypt		
联系人电话加密
string	否	C2		可空		否	否
32	channel_code		
渠道号
string	否	C2		可空		否	否
33	channel_name		
渠道名称
string	否	C2		可空		否	否
34	order_status		
订单状态
8:待报价,10:待平台派单,20:待供应商接单,21:待供应商派单,22:待服务者接单,23:待服务,24:服务中,30:待付款,40:订单完成,50:订单取消,11:成团中
bigint	否	C2		可空		否	否
35	pay_type		
支付方式 1-线上2-线下3-无需
1:线上,2:线下,3:先服务后付款,4:先付款后服务,5:预付加尾款
bigint	否	C2		可空		否	否
36	pay_status		
付款状态 10-支付中台受理成功 20-处理中 30-成功 40-取消 50-申请退款
10:支付中台受理成功,20:处理中,30:成功,40:取消,50:申请退款
bigint	否	C2		可空		否	否
37	pay_time		
付款时间
string	否	C2		可空		否	否
38	user_remark		
用户备注
string	否	C2		可空		否	否
39	platform_remark		
平台备注
string	否	C2		可空		否	否
40	platform_user_remark		
云管家端用户备注
string	否	C2		可空		否	否
41	resblock_id		
小区id
bigint	否	C2		可空		否	否
42	resblock_name		
小区名称
string	否	C2		可空		否	否
43	bizcircle_id		
商圈id
bigint	否	C2		可空		否	否
44	bizcircle_name		
商圈名称
string	否	C2		可空		否	否
45	urgent_flag		
紧急单标识
0:非紧急单,1:紧急单,2:紧急转非紧急单
bigint	否	C2		可空		否	否
46	label_group		
订单标签一对多
1:检修,2:租金代扣,4:省心租自动下单,8:门锁工单,9:洽谈量房,10:装配,12:2.0订单,11:二手房门锁
string	否	C2		可空		否	否
47	order_type		
订单类型
4:委托保洁,5:市场保洁,6:公寓会员,7:搬家市场单,8:保洁周期卡,9:周期保洁,10:市场维修,11:洗衣储值卡,12:洗衣,13:保洁拼团券,14:微棠, 15:经纪人集采,16:轻托管维修单,17:用户集采,18:轻托管蓄客,19:保洁加单,20:轻托管美化,21:公寓酒店,22:小修订单,23:美租,24:美租装配, 25:美租装配,26:IOT门锁,27:省心租甲醛单,28:省心租基础设施单
bigint	否	C2		可空		否	否
48	visible_to_tenant		
对租客可见
bigint	否	C2		可空		否	否
49	house_resource_id		
托管房源编码
bigint	否	C2		可空		否	否
50	lease_status		
房屋出租状态 创建订单那时刻
1:未出租,2:未入住,3:已出租
bigint	否	C2		可空		否	否
51	service_order_code		
服务单编码
string	否	C2		可空		否	否
52	service_order_status_code		
服务单状态编码
0:初始态,5:供应商已接单,10:待派单,20:待重新派单,30:待接单,40:待服务,50:服务中,60:服务挂起,65:待付款,70:已完成,80:已取消
bigint	否	C2		可空		否	否
53	service_order_status_name		
服务单状态名称
string	否	C2		可空		否	否
54	service_order_supplier_code		
供应商编码
bigint	否	C2		可空		否	否
55	service_order_supplier_name		
供应商名称
string	否	C2		可空		否	否
56	parent_service_order_code		
父服务单编号
string	否	C2		可空		否	否
57	service_order_professional_mobile		
服务者手机号
string	否	C2		可空		否	否
58	service_order_professional_name		
服务者姓名
string	否	C2		可空		否	否
59	service_order_professional_ucid		
服务者ucid
bigint	否	C2		可空		否	否
60	service_order_remark		
服务单备注
string	否	C2		可空		否	否
61	service_order_remark_time		
服务单备注时间
string	否	C2		可空		否	否
62	service_order_remark_name		
服务单备注人
string	否	C2		可空		否	否
63	service_order_professional_mobile_assist		
服务者电话摘要
string	否	C2		可空		否	否
64	service_order_professional_mobile_cipher		
服务者电话加密
string	否	C2		可空		否	否
65	service_order_child_status_code		
子状态
-1:默认值,0:初始态,5:供应商已接单,10:待派单,20:待重新派单,30:待接单,40:待服务,41:待搬-运单,42:待运-运单,43:待运-搬卸运单,50:服务中,51:待检修,52:检修中,53:检修完工-待用户确认,54:待服务者确认,55:服务者已确认,56:搬中,57:运中,58:待卸,59:卸中,591:卸完,592:运完-运单,60:服务挂起,65:待付款,70:已完成,80:已取消,601:待用户验收,602:用户验收完成
bigint	否	C2		可空		否	否
66	service_order_child_status_name		
子状态名称
string	否	C2		可空		否	否
67	service_order_is_first_order		
是否首次下单
bigint	否	C2		可空		否	否
68	service_order_type		
服务单类型
bigint	否	C2		可空		否	否
69	rent_unit_status_name		
当前房源出租状态
string	否	C2		可空		否	否
70	housein_contract_code		
收房合同编码
string	否	C2		可空		否	否
71	manager_ucid		
房管人ucid
bigint	否	C2		可空		否	否
72	manager_no		
房管人no
bigint	否	C2		可空		否	否
73	manager_name		
房管人姓名
string	否	C2		可空		否	否
74	immediate_superior_ucid		
房管人上级ucid
bigint	否	C2		可空		否	否
75	immediate_superior_name		
房管人上级姓名
string	否	C2		可空		否	否
76	manager_corp_code		
房管人公司编码
string	否	C2		可空		否	否
77	manager_corp_name		
房管人公司名称
string	否	C2		可空		否	否
78	manager_func_code		
房管人运营/职能/董事会编码
string	否	C2		可空		否	否
79	manager_func_name		
房管人运营/职能/董事会
string	否	C2		可空		否	否
80	manager_region_code		
房管人 运营管理大区/中心编码
string	否	C2		可空		否	否
81	manager_region_name		
房管人运营管理大区/中心
string	否	C2		可空		否	否
82	manager_marketing_code		
房管人营销大区/部门编码
string	否	C2		可空		否	否
83	manager_marketing_name		
房管人营销大区/部门
string	否	C2		可空		否	否
84	manager_area_code		
房管人业务区域/组编码
string	否	C2		可空		否	否
85	manager_area_name		
房管人业务区域/组
string	否	C2		可空		否	否
86	manager_shop_code		
房管人门店编码
string	否	C2		可空		否	否
87	manager_shop_name		
房管人 门店
string	否	C2		可空		否	否
88	manager_team_code		
房管人店组编码
string	否	C2		可空		否	否
89	manager_team_name		
房管人店组
string	否	C2		可空		否	否
90	manager_brand_code		
房管人品牌编码
string	否	C2		可空		否	否
91	manager_brand_name		
房管人品牌
string	否	C2		可空		否	否
92	protocol_type		
收房合同版本
string	否	C2		可空		否	否
93	service_start_time		
预约服务开始时间
string	否	C2		可空		否	否
94	service_end_time		
预约服务结束时间
string	否	C2		可空		否	否
95	modified_service_start_time		
修改后服务开始时间
string	否	C2		可空		否	否
96	modified_service_end_time		
修改后服务结束时间
string	否	C2		可空		否	否
97	modispatch_times		
改派次数
bigint	否	C2		可空		否	否
98	call_state		
外呼状态
bigint	否	C2		可空		否	否
99	first_suc_call_time		
首次成功呼叫时间
string	否	C2		可空		否	否
100	first_call_time		
首次呼叫时间
string	否	C2		可空		否	否
101	first_dispatch_time		
首次派单时间
string	否	C2		可空		否	否
102	last_dispatch_time		
最近派单时间
string	否	C2		可空		否	否
103	first_receive_time		
首次接单时间
string	否	C2		可空		否	否
104	last_receive_time		
最近接单时间
string	否	C2		可空		否	否
105	first_sign_time		
首次签到时间
string	否	C2		可空		否	否
106	last_sign_time		
最近签到时间
string	否	C2		可空		否	否
107	last_modify_serivce_time_operator_role		
最近修改服务时间角色
bigint	否	C2		可空		否	否
108	last_modify_serivce_time_reason		
最近修改服务时间原因
string	否	C2		可空		否	否
109	last_modify_serivce_time		
最近修改服务时间
string	否	C2		可空		否	否
110	last_modify_serivce_time_renterstatus		
最近改约租客确认情况
bigint	否	C2		可空		否	否
111	last_modify_serivce_time_renternoagree_reason		
最近改约租客不同意改约原因
string	否	C2		可空		否	否
112	professional_modify_service_time_times		
服务者修改服务时间次数
bigint	否	C2		可空		否	否
113	first_suspend_time		
首次挂起时间
string	否	C2		可空		否	否
114	last_suspend_time		
最近挂起时间
string	否	C2		可空		否	否
115	first_resume_time		
首次恢复时间
string	否	C2		可空		否	否
116	last_resume_time		
最近恢复时间
string	否	C2		可空		否	否
117	last_suspend_reason		
最近挂起原因
string	否	C2		可空		否	否
118	last_suspend_remark		
最近挂起备注
string	否	C2		可空		否	否
119	suspend_times		
挂起次数
bigint	否	C2		可空		否	否
120	suspend_days		
挂起天数
bigint	否	C2		可空		否	否
121	service_order_complete_time		
完工时间
string	否	C2		可空		否	否
122	service_hours		
订单服务总时长（小时）
decimal(20,2)	否	C2		可空		否	否
123	check_time		
验收时间
string	否	C2		可空		否	否
124	check_role		
验收角色
bigint	否	C2		可空		否	否
125	order_complete_time		
完单时间
string	否	C2		可空		否	否
126	user_evaluation_star		
用户评价星
bigint	否	C2		可空		否	否
127	user_evaluation_time		
用户评价时间
string	否	C2		可空		否	否
128	cancel_role		
服务单取消角色
0:默认值,1:服务者,2:云管家,3:供应商,4:运营,5:C端用户,6:B端用户,99:系统
bigint	否	C2		可空		否	否
129	cancel_reason		
服务单取消原因
string	否	C2		可空		否	否
130	pt		
分区字段
string	否	C2		可空		否	是
131	property_code		
检修单编码
string	否	C2		可空		否	否
132	order_evaluation_content		
订单评价内容
string	否	C2		可空		否	否
133	sign_state		
签到异常
bigint	否	C2		可空		否	否
134	is_contact_advance		
是否上门前一天22点致电
bigint	否	C2		可空		否	否
135	is_late		
迟到/爽约
bigint	否	C2		可空		否	否
136	is_has_nocust_change		
是否存在非客改约
bigint	否	C2		可空		否	否
137	is_currday_complete		
否当天完工
bigint	否	C2		可空		否	否
138	is_in5day_complete		
是否5日完工
bigint	否	C2		可空		否	否
139	urgent_is_contact_advance		
紧急单是否1小时内致电
bigint	否	C2		可空		否	否
140	urgent_is_sign_advance		
紧急单是否2小时内上门
bigint	否	C2		可空		否	否
141	user_evaluation_remark		
用户评价备注
string	否	C2		可空		否	否
142	new_service_start_time		
最新服务开始时间
string	否	C2		可空		否	否
143	houseout_contract_code		
出房合同编码
string	否	C2		可空		否	否
144	houseout_contract_sign_time		
出房合同签约时间
string	否	C2		可空		否	否
145	cancel_time		
取消时间
string	否	C2		可空		否	否
146	cancel_name		
取消人
string	否	C2		可空		否	否
147	examine_task_type		
检修任务类型
3:检修,12:复检
bigint	否	C2		可空		否	否
148	nocust_change_operator_ucid		
非客改约操作人ucid
bigint	否	C2		可空		否	否
149	nocust_change_operator_name		
非客改约操作人
string	否	C2		可空		否	否
150	nocust_change_reason		
非客改约原因
string	否	C2		可空		否	否
151	order_cancel_reason		
订单取消原因
string	否	C2		可空		否	否
152	performance_mode		
履约模式 0:普通单 1:紧急单 2:加急单
bigint	否	C2		可空		否	否
153	professional_tag_category		
服务者标签分类
string	否	C2		可空		否	否
154	check_name_type		
验收方式
string	否	C2		可空		否	否
155	order_commodity_list		
下单时商品列表
商品编码:::商品名称|服务项编码:::服务项名称|功能间id:::功能间名称|故障list|||商品编码:::商品名称|服务项编码:::服务项名称|功能间id:::功能间名称|故障list
string	否	C2		可空		否	否
156	order_is_has_lock		
下单时商品是否含门锁
bigint	否	C2		可空		否	否
157	real_commodity_list		
实际商品列表
string	否	C2		可空		否	否
