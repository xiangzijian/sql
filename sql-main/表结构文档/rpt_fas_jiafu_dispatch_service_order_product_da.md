序号        字段名称        参照表及字段        字段中文名        描述        枚举值        数据类型        是否加密        安全级别        单位        是否可空        默认值        是否主键        是否分区字段
1        id                
主键id
原字段名:id
bigint        否        C2                可空                否        否
2        product_code                
商品code
原字段名:product_code 商品code
string        否        C2                可空                否        否
3        product_name                
商品名称
原字段名:product_name
string        否        C2                可空                否        否
4        service_code                
一级类别编码
原字段名:service_code 一级类别编码
string        否        C2                可空                否        否
5        service_name                
一级类别名称
原字段名:service_name 一级类别名称
string        否        C2                可空                否        否
6        sub_service_code                
二级类别编码
原字段名:sub_service_code 二级类别编码
string        否        C2                可空                否        否
7        sub_service_name                
二级类别名称
原字段名:sub_service_name 二级类别名称
string        否        C2                可空                否        否
8        three_level_service_code                
三级类别编码
原字段名:three_level_service_code 三级类别编码
string        否        C2                可空                否        否
9        three_level_service_name                
三级类别名称
原字段名:three_level_service_name 三级类别名称
string        否        C2                可空                否        否
10        service_order_code                
服务单号
原字段名:service_order_code 服务单号
string        否        C2                可空                否        否
11        create_name                
创建人姓名
原字段名:create_name
string        否        C2                可空                否        否
12        create_time                
创建时间
原字段名:create_time
string        否        C2                可空                否        否
13        update_name                
修改人
原字段名:update_name 修改人
string        否        C2                可空                否        否
14        update_time                
修改时间
原字段名:update_time
string        否        C2                可空                否        否
15        is_delete                
删除标记,1是删除
原字段名:is_delete 原字段名:is_delete;
bigint        否        C2                可空                否        否
16        pt                
时间分区
原字段名:pt 时间分区
string        否        C2                可空                否        是
17        function_name_id                
function_name_id
bigint        否        C2                可空                否        否
18        function_name                
function_name
string        否        C2                可空                否        否
19        sort_number                
sort_number
bigint        否        C2                可空                否        否
20        status                
status
bigint        否        C2                可空                否        否
21        reason_code                
reason_code
bigint        否        C2                可空                否        否
22        reason                
reason
string        否        C2                可空                否        否
23        source                
source
bigint        否        C2                可空                否        否