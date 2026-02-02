# 数据库表结构文档

## 目录说明

本目录用于存放线上数据库的表结构文档，方便在离线开发环境中查看表结构信息。

## 如何导出表结构

### 方法一：使用 SHOW CREATE TABLE（推荐）

在线上数据库执行以下SQL，将结果保存到对应的表结构文件中：

```sql
-- 示例：导出表结构
SHOW CREATE TABLE olap.olap_hj_fas_main_order_service_info_da;
```

### 方法二：使用 DESCRIBE/DESC

```sql
-- 查看表结构
DESC olap.olap_hj_fas_main_order_service_info_da;
-- 或
DESCRIBE olap.olap_hj_fas_main_order_service_info_da;
```

### 方法三：查询系统表（适用于Hive/Spark）

```sql
-- Hive/Spark 查询表结构
DESCRIBE FORMATTED olap.olap_hj_fas_main_order_service_info_da;
-- 或
SHOW COLUMNS FROM olap.olap_hj_fas_main_order_service_info_da;
```

### 方法四：导出为DDL语句

```sql
-- 生成完整的建表语句
SHOW CREATE TABLE olap.olap_hj_fas_main_order_service_info_da;
```

## 文件命名规范

- 使用表名作为文件名（将点号替换为下划线）
- 例如：`olap_olap_hj_fas_main_order_service_info_da.md`
- 或使用更简洁的名称：`olap_hj_fas_main_order_service_info_da.md`

## 文档格式建议

每个表结构文档应包含：

1. **表基本信息**
   - 数据库名
   - 表名
   - 表说明/用途

2. **字段信息**
   - 字段名
   - 数据类型
   - 是否允许NULL
   - 默认值
   - 字段说明

3. **分区信息**（如有）
   - 分区字段
   - 分区类型

4. **索引信息**（如有）

5. **备注**
   - 更新日期
   - 其他说明

## 快速查找

使用IDE的全局搜索功能，可以快速查找字段名或表名。




