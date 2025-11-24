-- ============================================
-- 表结构导出脚本示例
-- 使用方法：在线上数据库执行对应SQL，将结果保存到表结构文档目录
-- ============================================

-- ============================================
-- 方法1：使用 SHOW CREATE TABLE（推荐）
-- ============================================
-- 优点：包含完整的建表语句，包括分区、存储格式等
SHOW CREATE TABLE olap.olap_hj_fas_main_order_service_info_da;
SHOW CREATE TABLE rpt.rpt_complain_order_details;
SHOW CREATE TABLE rpt.rpt_fas_light_hosting_order_detail_da;
SHOW CREATE TABLE rpt.rpt_weixiu_abnormal_checkin_list;
SHOW CREATE TABLE rpt.rpt_weixiu_abnormal_p;

-- ============================================
-- 方法2：使用 DESCRIBE（查看字段信息）
-- ============================================
DESC olap.olap_hj_fas_main_order_service_info_da;
DESC rpt.rpt_complain_order_details;
DESC rpt.rpt_fas_light_hosting_order_detail_da;
DESC rpt.rpt_weixiu_abnormal_checkin_list;
DESC rpt.rpt_weixiu_abnormal_p;

-- ============================================
-- 方法3：使用 DESCRIBE FORMATTED（Hive/Spark，包含详细信息）
-- ============================================
DESCRIBE FORMATTED olap.olap_hj_fas_main_order_service_info_da;
DESCRIBE FORMATTED rpt.rpt_complain_order_details;
DESCRIBE FORMATTED rpt.rpt_fas_light_hosting_order_detail_da;
DESCRIBE FORMATTED rpt.rpt_weixiu_abnormal_checkin_list;
DESCRIBE FORMATTED rpt.rpt_weixiu_abnormal_p;

-- ============================================
-- 方法4：查询系统表获取表结构（适用于Hive）
-- ============================================
-- 查询字段信息
SELECT 
    col_name,
    data_type,
    comment
FROM information_schema.columns
WHERE table_schema = 'olap' 
  AND table_name = 'olap_hj_fas_main_order_service_info_da'
ORDER BY ordinal_position;

-- ============================================
-- 批量导出所有表结构的脚本模板
-- ============================================
-- 可以根据需要修改表名列表
-- 建议：将输出结果分别保存到对应的 .md 文件中




