序号        字段名称        参照表及字段        字段中文名        描述        枚举值        数据类型        是否加密        安全级别        单位        是否可空        默认值        是否主键        是否分区字段
1        id                
主键
bigint        否        C2                不可空        -911        是        否
2        service_order_code                
服务单号
string        否        C2                不可空                否        否
3        product_code                
商品code
string        否        C2                不可空                否        否
4        product_name                
商品名称
string        否        C2                不可空                否        否
5        function_name_id                
功能间id
bigint        否        C2                不可空        -911        否        否
6        function_name                
功能间
string        否        C2                不可空                否        否
7        fault_point_id                
点位ID
bigint        否        C2                不可空        -911        否        否
8        fault_point_name                
点位名称
string        否        C2                不可空                否        否
9        level1_code                
一级类别编码
string        否        C2                不可空                否        否
10        level1_name                
一级类别名称
string        否        C2                不可空                否        否
11        level2_code                
二级类别编码
string        否        C2                不可空                否        否
12        level2_name                
二级类别名称
string        否        C2                不可空                否        否
13        level3_code                
三级类别编码
string        否        C2                不可空                否        否
14        level3_name                
三级类别名称
string        否        C2                不可空                否        否
15        product_status                
商品状态
0:可操作,1:不可操作
bigint        否        C2                不可空        -911        否        否
16        source                
数据来源
1:下单人添加,2:服务者添加
bigint        否        C2                不可空        -911        否        否
17        accept_status                
验收状态
-1:未验收,0:未通过,1:通过
bigint        否        C2                不可空        -911        否        否
18        accept_reason                
验收不通过原因
string        否        C2                不可空                否        否
19        operate_type                
操作类型
1:完工,2:重新发起验收,3:验收驳回,4:验收通过
bigint        否        C2                不可空        -911        否        否
20        operate_ucid                
操作人
bigint        否        C2                不可空        -911        否        否
21        operate_name                
操作人姓名
string        否        C2                不可空                否        否
22        operate_time                
操作时间
string        否        C2                不可空        1000-01-01 00:00:00        否        否
23        pt                
时间分区
string        否        C2                不可空                否        是