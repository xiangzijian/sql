SELECT
    MONTH(TO_DATE(create_time))      AS month_no,        -- 1-12 月
    commodity_name,
    fault_desc_ext,
    COUNT(DISTINCT order_no)        AS order_cnt        -- 统计订单数
FROM olap.olap_hj_fas_main_order_commodity_da
WHERE MONTH(TO_DATE(create_time)) BETWEEN 1 AND 7       -- 只要 1-7 月
--  AND pt BETWEEN '2025-01-01' AND '2025-07-31'        -- 如需可加分区条件
GROUP BY
    MONTH(TO_DATE(create_time)),
    commodity_name,
    fault_desc_ext
ORDER BY
    month_no,
    commodity_name,
    fault_desc_ext;