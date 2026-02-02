-- 按城市和月份统计主楼盘在管天数、检修和租期维修数据
-- 统计维度：不同城市 + 2025年月维度
-- 统计指标：主楼盘总在管天数、检修服务单编码数量、检修商品数量、租期维修服务单编码数量、租期维修商品数量

WITH
-- 1. 生成2025年所有月份序列
month_sequence AS (
    SELECT 2025 AS year_num, 1 AS month_seq UNION ALL
    SELECT 2025, 2 UNION ALL
    SELECT 2025, 3 UNION ALL
    SELECT 2025, 4 UNION ALL
    SELECT 2025, 5 UNION ALL
    SELECT 2025, 6 UNION ALL
    SELECT 2025, 7 UNION ALL
    SELECT 2025, 8 UNION ALL
    SELECT 2025, 9 UNION ALL
    SELECT 2025, 10 UNION ALL
    SELECT 2025, 11 UNION ALL
    SELECT 2025, 12
),

-- 2. 获取所有城市列表（从合同数据中）
city_list AS (
    SELECT DISTINCT city_name
    FROM olap.olap_trusteeship_hdel_housein_da
    WHERE pt = '20251231000000'
        AND contract_status_code IN (2, 3, 4, 5)
        AND city_name IS NOT NULL
),

-- 3. 城市-月份笛卡尔积
city_month_combination AS (
    SELECT 
        c.city_name,
        m.year_num,
        m.month_seq,
        CONCAT(m.year_num, '-', LPAD(CAST(m.month_seq AS STRING), 2, '0'), '-01') AS month_start_date,
        CASE 
            WHEN m.month_seq IN (1, 3, 5, 7, 8, 10, 12) THEN CONCAT(m.year_num, '-', LPAD(CAST(m.month_seq AS STRING), 2, '0'), '-31')
            WHEN m.month_seq IN (4, 6, 9, 11) THEN CONCAT(m.year_num, '-', LPAD(CAST(m.month_seq AS STRING), 2, '0'), '-30')
            WHEN m.month_seq = 2 THEN CONCAT(m.year_num, '-02-29')  -- 2025年不是闰年，但用29兼容计算
        END AS month_end_date
    FROM city_list c
    CROSS JOIN month_sequence m
),

-- 4. 每个房源的合同信息（按城市、房源编码去重）
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
    FROM olap.olap_trusteeship_hdel_housein_da
    WHERE pt = '20251231000000'
        AND contract_status_code IN (2, 3, 4, 5)
        AND trusteeship_housedel_code IS NOT NULL
        AND city_name IS NOT NULL
    GROUP BY
        trusteeship_housedel_code, resblock_id, resblock_name, city_name
),

-- 5. 计算每个房源在每个月的在管天数
house_monthly_days AS (
    SELECT
        hci.city_name,
        hci.resblock_id,
        hci.resblock_name,
        hci.trusteeship_housedel_code,
        cmc.year_num,
        cmc.month_seq,
        cmc.month_start_date,
        cmc.month_end_date,
        -- 计算单个房源在该月的在管天数
        CASE
            WHEN TO_DATE(hci.latest_end_date) < TO_DATE(cmc.month_start_date) 
                OR TO_DATE(hci.earliest_sign_date) > TO_DATE(cmc.month_end_date) 
            THEN 0
            ELSE DATEDIFF(
                LEAST(TO_DATE(cmc.month_end_date), TO_DATE(hci.latest_end_date)),
                GREATEST(TO_DATE(cmc.month_start_date), TO_DATE(hci.earliest_sign_date))
            ) + 1
        END AS house_managed_days
    FROM house_contract_info hci
    CROSS JOIN city_month_combination cmc
    WHERE hci.city_name = cmc.city_name
),

-- 6. 按城市、年月、楼盘聚合在管天数（只统计在管天数>0的房源）
resblock_monthly_stats AS (
    SELECT
        city_name,
        year_num,
        month_seq,
        resblock_id,
        resblock_name,
        SUM(house_managed_days) AS total_managed_days
    FROM house_monthly_days
    WHERE house_managed_days > 0
    GROUP BY
        city_name, year_num, month_seq, resblock_id, resblock_name
),

-- 7. 获取检修数据（label_group IN ('1', '25') 或 lease_status IN ('-1', '1')）
repair_order_data AS (
    SELECT
        o.city_name,
        o.resblock_id,
        o.service_order_code,
        c.item_name AS commodity_name,
        CAST(SUBSTR(o.order_create_time, 1, 4) AS INT) AS order_year,
        CAST(SUBSTR(o.order_create_time, 6, 2) AS INT) AS order_month,
        o.order_create_time
    FROM olap.olap_hj_fas_main_order_service_info_da o
    LEFT JOIN olap.olap_hj_fas_main_order_commodity_da c
        ON o.order_no = c.order_no
        AND c.pt = '20251231000000'
        AND c.commodity_type = 1
    WHERE o.pt = '20251231000000'
        AND o.order_create_time >= '2025-01-01 00:00:00' 
        AND o.order_create_time <= '2025-12-31 23:59:59'
        AND o.order_type = '16'       -- 维修订单类型
        AND (o.label_group IN ('1', '25') OR o.lease_status IN ('-1', '1'))  -- 检修条件
        AND o.label_group NOT IN ('8')
        AND o.city_name IS NOT NULL
),

-- 8. 检修数据按城市、年月、楼盘统计
repair_monthly_stats AS (
    SELECT
        city_name,
        order_year AS year_num,
        order_month AS month_seq,
        resblock_id,
        COUNT(DISTINCT service_order_code) AS repair_service_count,
        COUNT(commodity_name) AS repair_commodity_count
    FROM repair_order_data
    GROUP BY
        city_name, order_year, order_month, resblock_id
),

-- 9. 获取租期维修数据（租后维修：label_group NOT IN ('1', '8', '25') 且 lease_status IN (2, 3)）
lease_repair_order_data AS (
    SELECT
        o.city_name,
        o.resblock_id,
        o.service_order_code,
        c.item_name AS commodity_name,
        CAST(SUBSTR(o.order_create_time, 1, 4) AS INT) AS order_year,
        CAST(SUBSTR(o.order_create_time, 6, 2) AS INT) AS order_month,
        o.order_create_time
    FROM olap.olap_hj_fas_main_order_service_info_da o
    LEFT JOIN olap.olap_hj_fas_main_order_commodity_da c
        ON o.order_no = c.order_no
        AND c.pt = '20251231000000'
        AND c.commodity_type = 1
    WHERE o.pt = '20251231000000'
        AND o.order_create_time >= '2025-01-01 00:00:00' 
        AND o.order_create_time <= '2025-12-31 23:59:59'
        AND o.order_type = '16'       -- 维修订单类型
        AND o.label_group NOT IN ('1', '8', '25')  -- 排除检修和其他特殊类型
        AND o.lease_status IN (2, 3)  -- 租期状态：2-租中，3-已退租
        AND o.city_name IS NOT NULL
),

-- 10. 租期维修数据按城市、年月、楼盘统计
lease_repair_monthly_stats AS (
    SELECT
        city_name,
        order_year AS year_num,
        order_month AS month_seq,
        resblock_id,
        COUNT(DISTINCT service_order_code) AS lease_repair_service_count,
        COUNT(commodity_name) AS lease_repair_commodity_count
    FROM lease_repair_order_data
    GROUP BY
        city_name, order_year, order_month, resblock_id
),

-- 11. 按城市和月份汇总所有楼盘的指标
city_monthly_summary AS (
    SELECT
        rms.city_name,
        rms.year_num,
        rms.month_seq,
        SUM(rms.total_managed_days) AS total_managed_days,
        SUM(COALESCE(rep.repair_service_count, 0)) AS total_repair_service_count,
        SUM(COALESCE(rep.repair_commodity_count, 0)) AS total_repair_commodity_count,
        SUM(COALESCE(lrep.lease_repair_service_count, 0)) AS total_lease_repair_service_count,
        SUM(COALESCE(lrep.lease_repair_commodity_count, 0)) AS total_lease_repair_commodity_count
    FROM resblock_monthly_stats rms
    LEFT JOIN repair_monthly_stats rep
        ON rms.city_name = rep.city_name
        AND rms.year_num = rep.year_num
        AND rms.month_seq = rep.month_seq
        AND rms.resblock_id = rep.resblock_id
    LEFT JOIN lease_repair_monthly_stats lrep
        ON rms.city_name = lrep.city_name
        AND rms.year_num = lrep.year_num
        AND rms.month_seq = lrep.month_seq
        AND rms.resblock_id = lrep.resblock_id
    GROUP BY
        rms.city_name, rms.year_num, rms.month_seq
)

-- 最终输出：按城市和月份汇总
SELECT
    city_name AS `城市名称`,
    year_num AS `年份`,
    month_seq AS `月份`,
    CONCAT(year_num, '-', LPAD(month_seq, 2, '0')) AS `年月`,
    total_managed_days AS `主楼盘总在管天数`,
    total_repair_service_count AS `检修服务单编码数量`,
    total_repair_commodity_count AS `检修商品数量`,
    total_lease_repair_service_count AS `租期维修服务单编码数量`,
    total_lease_repair_commodity_count AS `租期维修商品数量`
FROM city_monthly_summary
ORDER BY
    city_name, year_num, month_seq;


-- ===========================================
-- 补充说明：
-- ===========================================
-- 1. 主楼盘总在管天数：统计该城市该月所有楼盘的在管天数总和
-- 2. 检修服务单编码数量：order_type = '16' 且 (label_group IN ('1', '25') 或 lease_status IN ('-1', '1')) 的服务单数量
-- 3. 检修商品数量：检修订单中的商品（item_name）数量
-- 4. 租期维修服务单编码数量：order_type = '16' 且 label_group NOT IN ('1', '8', '25') 且 lease_status IN (2, 3) 的服务单数量
-- 5. 租期维修商品数量：租期维修订单中的商品数量
-- 
-- 字段说明：
-- - label_group: '1'/'25' = 检修相关, '8' = 需要排除的特殊类型
-- - lease_status: '-1'/'1' = 检修租期状态, '2' = 租中, '3' = 已退租
-- - order_type: '16' = 维修订单类型
-- - commodity_type: 1 = 实物商品（用于统计商品数量）
-- 
-- 数据说明：
-- - 统计周期：2025年1-12月
-- - 数据快照：20251231000000（即2025年12月31日）
-- - 如需筛选特定城市，可在最终 SELECT 后添加 WHERE city_name IN ('城市1', '城市2') 条件
