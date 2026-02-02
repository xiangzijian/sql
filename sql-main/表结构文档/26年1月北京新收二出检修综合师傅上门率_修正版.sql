-- 统计26年1月份北京现在新收和二出的房子里，检修维修单中综合师傅上门率
-- 新收=首出（delivery_houseout_rank = 1），二出=非首出（delivery_houseout_rank > 1）
-- 修正：添加与参考SQL一致的筛选条件

WITH 
-- 获取新收和二出的房源信息
house_info AS (
    SELECT DISTINCT
        order_code,
        city_name,
        CASE 
            WHEN delivery_houseout_rank = 1 THEN '首出'
            WHEN delivery_houseout_rank > 1 THEN '非首出'
            ELSE NULL 
        END AS `首出or非首出`
    FROM olap.olap_trusteeship_hdel_examine_divide_da
    WHERE pt = '20260127000000'  -- 使用与参考SQL一致的分区日期
        AND city_name = '北京市'
        AND delivery_houseout_rank IS NOT NULL
        AND order_code IS NOT NULL
),

-- 获取检修维修订单（按订单号去重，添加与参考SQL一致的筛选条件）
repair_orders AS (
    SELECT DISTINCT
        a.order_no,
        a.order_create_time,
        a.city_name,
        a.service_order_professional_ucid,
        a.service_order_professional_name,
        a.first_sign_time,
        a.label_group,
        a.lease_status
    FROM olap.olap_hj_fas_main_order_service_info_da a
    -- 添加与参考SQL一致的筛选条件：关联 rpt.rpt_fas_light_hosting_order_detail_da 表
    INNER JOIN (
        SELECT 
            order_no AS oth_orderno
        FROM rpt.rpt_fas_light_hosting_order_detail_da
        WHERE pt = '20260127000000'
            AND vison_type = '4.0'
            AND service_name IN ('维修', '燃气')
            AND order_type = '16'
            AND commodity_name_list1 != '漏水专项检修'
            AND commodity_name_list1 NOT IN (
                '夏季空调预检', 
                'SCM00300001672373', 
                '漏水专项检修', 
                '消防器材', 
                '定损', 
                '漏水定损', 
                '火灾定损', 
                '其他定损', 
                '京北漏水定损', 
                '京南漏水定损', 
                '京北火灾定损', 
                '京南火灾定损', 
                '京北其他定损', 
                '京南其他定损'
            )
            AND supplier_name NOT IN (
                '上海兰宫建筑装饰有限公司',
                '上海尚礼实业有限公司',
                '上海苏皖贸易有限公司',
                '上海再旭保洁服务有限公司',
                '源和里仁家具海安有限公司',
                '匠云（北京）科技有限公司'
            )
    ) c ON a.order_no = c.oth_orderno
    WHERE a.pt = '20260127000000'
        AND a.city_name = '北京市'
        -- 检修单判断：与参考SQL一致
        AND (a.label_group IN ('1', '25') OR a.lease_status IN ('-1', '1'))
        -- 时间范围：与参考SQL一致（到1月27日）
        AND a.order_create_time BETWEEN '2026-01-01 00:00:00' AND '2026-01-27 23:59:59'
        AND a.order_no IS NOT NULL
),

-- 获取综合师傅信息（ability_list包含'维修综合'）
comprehensive_staff AS (
    SELECT DISTINCT
        staff_ucid,
        name AS staff_name,
        ability_list
    FROM olap.olap_fas_mht_staff_detail_da
    WHERE pt = '20260127000000'
        AND staff_ucid IS NOT NULL
        AND ability_list IS NOT NULL
        AND ability_list LIKE '%维修综合%'  -- 包含'维修综合'字的就是综合师傅
)

-- 主查询：统计综合师傅上门率
SELECT 
    h.`首出or非首出`,
    COUNT(DISTINCT r.order_no) AS `总订单数`,
    COUNT(DISTINCT CASE 
        WHEN r.first_sign_time IS NOT NULL 
            AND SUBSTR(r.first_sign_time, 1, 4) NOT IN ('1990', '2050', '1000')
            AND r.first_sign_time != '1000-01-01 00:00:00'
        THEN r.order_no 
    END) AS `上门订单数`,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN r.first_sign_time IS NOT NULL 
                AND SUBSTR(r.first_sign_time, 1, 4) NOT IN ('1990', '2050', '1000')
                AND r.first_sign_time != '1000-01-01 00:00:00'
            THEN r.order_no 
        END) * 100.0 / 
        NULLIF(COUNT(DISTINCT r.order_no), 0), 
        2
    ) AS `综合师傅上门率(%)`
FROM house_info h
INNER JOIN repair_orders r
    ON h.order_code = r.order_no
    AND h.city_name = r.city_name
INNER JOIN comprehensive_staff cs
    ON r.service_order_professional_ucid = cs.staff_ucid
WHERE h.`首出or非首出` IS NOT NULL
GROUP BY h.`首出or非首出`
ORDER BY h.`首出or非首出`;
