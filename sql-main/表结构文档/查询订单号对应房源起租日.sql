-- 查询指定订单号对应房源的起租日
-- 要求：距离订单创建时间之后最近的起租日
WITH target_orders AS (
    SELECT 
        order_no,
        house_resource_id,
        order_create_time,
        city_name
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '20250125000000'
        AND order_no IN (
            'T010020250615140554620790',
            'T010020250621123630316471',
            'T010020250628130205445453',
            'T010020250625181909051459'
        )
),

-- 获取房源的所有起租日记录（通过订单号关联）
house_rent_dates AS (
    SELECT DISTINCT
        order_code,
        contract_code,
        substr(effect_start_date, 1, 10) AS `起租日`,
        effect_start_date,
        property_submit_time,
        city_name,
        DENSE_RANK() OVER(PARTITION BY contract_code ORDER BY property_submit_time DESC) AS tijiao
    FROM olap.olap_trusteeship_hdel_examine_divide_da
    WHERE pt = '20250125000000'
        AND task_type <> 12
        AND effect_start_date IS NOT NULL
        AND substr(effect_start_date, 1, 10) NOT IN ('1000-01-01', '1990-01-01', '2050-01-01')
),

-- 关联订单和房源起租日，筛选订单创建时间之后的起租日
order_rent_mapping AS (
    SELECT 
        t.order_no AS `订单号`,
        t.order_create_time AS `订单创建时间`,
        t.house_resource_id AS `房源ID`,
        t.city_name AS `城市`,
        h.`起租日`,
        h.effect_start_date AS `完整起租时间`,
        h.contract_code AS `合同编码`,
        DATEDIFF(TO_DATE(h.`起租日`), TO_DATE(t.order_create_time)) AS `起租日距离订单创建天数`,
        ROW_NUMBER() OVER(
            PARTITION BY t.order_no 
            ORDER BY h.`起租日` ASC  -- 按起租日升序，取最近的（最小的正数天数）
        ) AS rn
    FROM target_orders t
    LEFT JOIN house_rent_dates h
        ON t.order_no = h.order_code  -- 通过订单号关联
        AND t.city_name = h.city_name
        AND TO_DATE(h.`起租日`) >= TO_DATE(t.order_create_time)  -- 起租日在订单创建时间之后
        AND h.tijiao = 1  -- 只取最后一次提交的记录
)

-- 最终查询：每个订单号对应的最近起租日
SELECT 
    `订单号`,
    `订单创建时间`,
    `房源ID`,
    `城市`,
    `起租日`,
    `完整起租时间`,
    `合同编码`,
    `起租日距离订单创建天数`
FROM order_rent_mapping
WHERE rn = 1  -- 取距离订单创建时间最近的起租日
ORDER BY `订单号`
