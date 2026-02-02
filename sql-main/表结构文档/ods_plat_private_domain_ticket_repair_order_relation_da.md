
## 表基本信息

- **数据库名**: `ods`
- **表名**: `ods_plat_private_domain_ticket_repair_order_relation_da`
- **表中文名**: 工单维修单关联关系表
- **表说明**: 咨询工单和维修单关系关联表
- **更新日期**: 2026-01-13

---



序号	字段名称	参照表及字段	字段中文名	描述	枚举值	数据类型	是否加密	安全级别	单位	是否可空	默认值	是否主键	是否分区字段
1	id		
id
bigint	否	C2		不可空	-911	否	否
2	ticket_id		
工单id
string	否	C2		不可空		否	否
3	repair_order		
家服维修单号
多个用,分隔
string	否	C2		不可空		否	否
4	ctime		
创建时间
string	否	C2		不可空	1000-01-01 00:00:00	否	否
5	mtime		
更新时间
string	否	C2		不可空	1000-01-01 00:00:00	否	否
6	pt		
时间分区
string	否	C2		不可空		否	是