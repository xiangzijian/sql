序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	id		
id
bigint	否	C2		不可空	-911	是	否
2	task_id		
租务任务id
string	否	C2		不可空		否	否
3	replace_order_code		
换新单订单编码
string	否	C2		不可空		否	否
4	original_order_code		
原订单编码
string	否	C2		不可空		否	否
5	commodity_code		
商品编码
string	否	C2		不可空		否	否
6	commodity_name		
商品名称
string	否	C2		不可空		否	否
7	no_maintain_reason_desc		
暂不维修原因
string	否	C2		不可空		否	否
8	create_time		
换新单创建时间
string	否	C2		不可空	1000-01-01 00:00:00	否	否
9	update_time		
换新单更新时间
string	否	C2		不可空	1000-01-01 00:00:00	否	否
10	pt		
时间分区
string	否	C2		不可空		否	是