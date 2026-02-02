-- 楼盘百日报修项及附近相似盘百日报修项
-- 完整版代码2：楼盘维度周期内在管天数报修项及附近相似楼盘在管天数与报修项分析
-- 时间维度：25年1月和12月
WITH
-- 1. 月份序列生成（2025年1月和2025年12月）
month_sequence AS (
 SELECT 2025 AS year_num, 1 AS month_seq UNION ALL
 SELECT 2025, 12
 ),
 
-- 2. 每个房源的合同信息（按房源编码去重，取最早的签约日期和最晚的结束日期）
house_contract_info AS (
 SELECT
 trusteeship_housedel_code,
 resblock_id,
 resblock_name,
 city_name,
 MIN(sign_date) AS earliest_sign_date,
 CASE
 WHEN COUNT(CASE WHEN terminate_time IS NOT NULL AND LENGTH(terminate_time) > 0 THEN 1 END) > 0
 THEN MIN(terminate_time)
 ELSE MIN(last_effect_end_date)
 END AS latest_end_date
 FROM
 olap.olap_trusteeship_hdel_housein_da
 WHERE
 pt = '20251231000000'
 AND city_name = '北京市'
 AND contract_status_code IN (2, 3, 4, 5)
 AND trusteeship_housedel_code IS NOT NULL
 GROUP BY
 trusteeship_housedel_code, resblock_id, resblock_name, city_name
 ),
-- 3. 计算每个房源在指定周期（2025-01-01到2025-12-31）内的在管天数
subquery AS (
 SELECT
 hci.resblock_id,
 hci.trusteeship_housedel_code,
 -- 单个房源在管天数（统计周期内有效）
 CASE
 WHEN LEAST(TO_DATE('2025-12-31'),
 TO_DATE(hci.latest_end_date)
 ) < LEAST(TO_DATE('2025-12-31'), GREATEST(TO_DATE('2025-01-01'), TO_DATE(hci.earliest_sign_date))) THEN 0
 ELSE DATEDIFF(
 LEAST(TO_DATE('2025-12-31'),
 TO_DATE(hci.latest_end_date)
 ),
 LEAST(TO_DATE('2025-12-31'), GREATEST(TO_DATE('2025-01-01'), TO_DATE(hci.earliest_sign_date)))
 ) + 1
 END AS `单个房源在管天数`
 FROM
 house_contract_info hci
 ),
-- 4. 统计小区的在管过房源量（仅包含在管天数>0的房源，核心筛选条件）
resblock_inventory_stats AS (
 SELECT
 hci.resblock_id,
 hci.resblock_name,
 COUNT(DISTINCT hci.trusteeship_housedel_code) AS `在管过房源量`,
 SUM(s.`单个房源在管天数`) AS `累计在管天数`
 FROM
 house_contract_info hci
 INNER JOIN  -- 强制筛选在管天数>0的房源
 subquery s
 ON hci.resblock_id = s.resblock_id
 AND hci.trusteeship_housedel_code = s.trusteeship_housedel_code
 AND s.`单个房源在管天数` > 0
 WHERE
 hci.trusteeship_housedel_code IS NOT NULL
 GROUP BY
 hci.resblock_id, hci.resblock_name
 HAVING
 COUNT(DISTINCT hci.trusteeship_housedel_code) > 0
 ),
-- 5. 小区分类（细化楼龄段和面积分类）
resblock_category AS (
 SELECT
 h.resblock_id,
 -- 细化楼龄段：<1985,[1985,1995),[1995,2005),[2005,2015),>=2015
 ROUND(AVG(CASE WHEN h.build_year != '-911' THEN h.build_year END), 2) AS `平均建筑年份`,
 CASE
 WHEN ROUND(AVG(CASE WHEN h.build_year != '-911' THEN h.build_year END), 2) < 1985 THEN 'lt1985'
 WHEN ROUND(AVG(CASE WHEN h.build_year != '-911' THEN h.build_year END), 2) BETWEEN 1985 AND 1995 THEN '1985_1995'
 WHEN ROUND(AVG(CASE WHEN h.build_year != '-911' THEN h.build_year END), 2) BETWEEN 1995 AND 2005 THEN '1995_2005'
 WHEN ROUND(AVG(CASE WHEN h.build_year != '-911' THEN h.build_year END), 2) BETWEEN 2005 AND 2015 THEN '2005_2015'
 WHEN ROUND(AVG(CASE WHEN h.build_year != '-911' THEN h.build_year END), 2) >= 2015 THEN 'gte2015'
 ELSE 'unknown'
 END AS `建筑年份分类`,
 -- 面积分类保持不变
 ROUND(AVG(CASE WHEN h.house_area > 20 AND h.house_area < 300 THEN h.house_area END), 2) AS `平均面积`,
 CASE
 WHEN ROUND(AVG(CASE WHEN h.house_area > 20 AND h.house_area < 300 THEN h.house_area END), 2) BETWEEN 20 AND 45 THEN '20_45'
 WHEN ROUND(AVG(CASE WHEN h.house_area > 20 AND h.house_area < 300 THEN h.house_area END), 2) BETWEEN 45 AND 75 THEN '45_75'
 WHEN ROUND(AVG(CASE WHEN h.house_area > 20 AND h.house_area < 300 THEN h.house_area END), 2) BETWEEN 75 AND 105 THEN '75_105'
 WHEN ROUND(AVG(CASE WHEN h.house_area > 20 AND h.house_area < 300 THEN h.house_area END), 2) BETWEEN 105 AND 135 THEN '105_135'
 WHEN ROUND(AVG(CASE WHEN h.house_area > 20 AND h.house_area < 300 THEN h.house_area END), 2) BETWEEN 135 AND 165 THEN '135_165'
 WHEN ROUND(AVG(CASE WHEN h.house_area > 20 AND h.house_area < 300 THEN h.house_area END), 2) >= 165 THEN '165_plus'
 ELSE 'unknown'
 END AS `面积分类`,
 ROUND(AVG(h.bedroom_num), 2) AS `平均卧室数量`,
 ROUND(AVG(h.is_has_elevator), 2) AS `是否有电梯系数`
 FROM
 olap.olap_trusteeship_hdel_housein_da h
 INNER JOIN
 resblock_inventory_stats ris
 ON h.resblock_id = ris.resblock_id
 WHERE
 h.pt = '20251231000000'
 AND h.city_name = '北京市'
 AND h.contract_status_code IN (2, 3, 4, 5)
 GROUP BY
 h.resblock_id
 ),
-- 6. 主小区基础信息
main_resblock AS (
 SELECT
 ris.resblock_id AS `小区id`,
 ris.resblock_name AS `小区名称`,
 rc.`平均建筑年份`,
 rc.`建筑年份分类`,
 rc.`平均面积`,
 rc.`面积分类`,
 rc.`平均卧室数量`,
 rc.`是否有电梯系数`,
 ris.`在管过房源量` AS `主楼盘在管过房源量`,
 ris.`累计在管天数` AS `主楼盘累计在管天数`
 FROM
 resblock_inventory_stats ris
 LEFT JOIN
 resblock_category rc
 ON ris.resblock_id = rc.resblock_id
 WHERE
 rc.`建筑年份分类` IS NOT NULL
 AND rc.`面积分类` IS NOT NULL
 ),
-- 7. 附近小区关系
nearby_resblock_ids AS (
 SELECT
 nr.resblock_id AS main_resblock_id,
 nr.resblock_id2 AS nearby_resblock_id
 FROM
 dim.dim_hj_resblock_between_distance_da nr
 INNER JOIN
 main_resblock mr
 ON nr.resblock_id = mr.`小区id`
 WHERE
 nr.pt = '20251231000000'
 AND nr.city_name = '北京市'
 AND nr.distance_km <= 0.5
 AND nr.resblock_id != nr.resblock_id2
 GROUP BY
 nr.resblock_id, nr.resblock_id2
 ),
-- 8. 同分类附近小区（在管数据）
matched_nearby_inventory AS (
 SELECT
 nri.main_resblock_id,
 nri.nearby_resblock_id,
 nis.`在管过房源量` AS nearby_house_count,
 nis.`累计在管天数` AS nearby_days
 FROM
 nearby_resblock_ids nri
 INNER JOIN
 resblock_inventory_stats nis
 ON nri.nearby_resblock_id = nis.resblock_id
 INNER JOIN
 resblock_category nrc
 ON nri.nearby_resblock_id = nrc.resblock_id
 INNER JOIN
 main_resblock mr
 ON nri.main_resblock_id = mr.`小区id`
 WHERE
 nrc.`建筑年份分类` = mr.`建筑年份分类`
 AND nrc.`面积分类` = mr.`面积分类`
 ),
-- 9. 在管数据的附近楼盘聚合指标
inventory_nearby_agg AS (
 SELECT
 main_resblock_id,
 COUNT(DISTINCT nearby_resblock_id) AS `inventory_附近相似楼盘数量`,
 SUM(nearby_house_count) AS `inventory_附近相似楼盘在管过房源量`,
 SUM(nearby_days) AS `inventory_附近相似楼盘累计在管天数`
 FROM
 matched_nearby_inventory
 GROUP BY
 main_resblock_id
 ),
-- 10. 报修数据筛选
filtered_main_order AS (
 SELECT
 o.resblock_id,
 o.service_order_code,
 c.item_name,
 o.bizcircle_name
 FROM
 olap.olap_hj_fas_main_order_service_info_da o
 LEFT JOIN
 olap.olap_hj_fas_main_order_commodity_da c
 ON o.order_no = c.order_no
 AND c.pt = '20251231000000'
 AND c.commodity_type = 1
 WHERE
 o.pt = '20251231000000'
 AND o.order_create_time BETWEEN '2025-01-01 00:00:00' AND '2025-12-31 23:59:59'
 AND o.service_code = '10003'
 AND o.order_type = '16'
 AND o.label_group NOT IN ('8')
 AND o.city_name = '北京市'
 ),
-- 11. 报修数据指标统计
repair_stats AS (
 SELECT
 resblock_id,
 COUNT(DISTINCT service_order_code) AS `主楼盘报修量`,
 COUNT(item_name) AS `主楼盘报修项数量`,
 MAX(bizcircle_name) AS bizcircle_name
 FROM
 filtered_main_order
 GROUP BY
 resblock_id
 ),
-- 12. 同分类附近小区的报修数据
matched_nearby_repair AS (
 SELECT
 nri.main_resblock_id,
 nri.nearby_resblock_id,
 COALESCE(rs.service_count, 0) AS nearby_repair_count,
 COALESCE(rs.item_count, 0) AS nearby_item_count,
 nis.`在管过房源量` AS nearby_house_count
 FROM
 nearby_resblock_ids nri
 INNER JOIN
 resblock_inventory_stats nis
 ON nri.nearby_resblock_id = nis.resblock_id
 INNER JOIN
 resblock_category nrc
 ON nri.nearby_resblock_id = nrc.resblock_id
 INNER JOIN
 main_resblock mr
 ON nri.main_resblock_id = mr.`小区id`
 LEFT JOIN (
 SELECT
 resblock_id,
 COUNT(DISTINCT service_order_code) AS service_count,
 COUNT(item_name) AS item_count
 FROM
 filtered_main_order
 GROUP BY
 resblock_id
 ) rs ON nri.nearby_resblock_id = rs.resblock_id
 WHERE
 nrc.`建筑年份分类` = mr.`建筑年份分类`
 AND nrc.`面积分类` = mr.`面积分类`
 ),
-- 13. 报修数据的附近楼盘聚合指标
repair_nearby_agg AS (
 SELECT
 main_resblock_id,
 COUNT(DISTINCT nearby_resblock_id) AS `repair_附近相似楼盘数量`,
 SUM(nearby_repair_count) AS `repair_附近相似楼盘总报修量`,
 SUM(nearby_item_count) AS `repair_附近相似楼盘总报修项数量`,
 SUM(nearby_house_count) AS `repair_附近相似楼盘在管过房源量`
 FROM
 matched_nearby_repair
 GROUP BY
 main_resblock_id
 )
-- 最终输出
SELECT
 mr.`小区id`,
 mr.`小区名称`,
 rs.bizcircle_name AS `商圈名称`,
 mr.`平均建筑年份`,
 mr.`建筑年份分类` AS `主楼盘建筑年份分类`,
 mr.`平均面积`,
 mr.`面积分类` AS `主楼盘面积分类`,
 mr.`平均卧室数量`,
 mr.`是否有电梯系数`,
 mr.`主楼盘在管过房源量`,
 mr.`主楼盘累计在管天数`,
 COALESCE(rs.`主楼盘报修量`, 0) AS `主楼盘报修量`,
 COALESCE(rs.`主楼盘报修项数量`, 0) AS `主楼盘报修项数量`,
 -- 在管数据的附近楼盘指标
 COALESCE(ina.`inventory_附近相似楼盘数量`, 0) AS `inventory_附近相似楼盘数量`,
 COALESCE(ina.`inventory_附近相似楼盘在管过房源量`, 0) AS `inventory_附近相似楼盘在管过房源量`,
 COALESCE(ina.`inventory_附近相似楼盘累计在管天数`, 0) AS `inventory_附近相似楼盘累计在管天数`,
 -- 报修数据的附近楼盘指标
 COALESCE(rna.`repair_附近相似楼盘数量`, 0) AS `repair_附近相似楼盘数量`,
 COALESCE(rna.`repair_附近相似楼盘总报修量`, 0) AS `repair_附近相似楼盘总报修量`,
 COALESCE(rna.`repair_附近相似楼盘总报修项数量`, 0) AS `repair_附近相似楼盘总报修项数量`,
 COALESCE(rna.`repair_附近相似楼盘在管过房源量`, 0) AS `repair_附近相似楼盘在管过房源量`
 FROM
 main_resblock mr
 LEFT JOIN
 repair_stats rs
 ON mr.`小区id` = rs.resblock_id
 LEFT JOIN
 inventory_nearby_agg ina
 ON mr.`小区id` = ina.main_resblock_id
 LEFT JOIN
 repair_nearby_agg rna
 ON mr.`小区id` = rna.main_resblock_id
 ORDER BY
 mr.`小区id`
