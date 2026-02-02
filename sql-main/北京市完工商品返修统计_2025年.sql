-- 北京市2025年按完工商品聚合的完工单量和返修量统计
-- 数据来源：rpt.rpt_wx_fanxiu_quan_mx

SELECT 
    product_name_1 AS `完工商品名称`,
    COUNT(DISTINCT order_no_1) AS order_no_1,  -- 完工总单量（去重）
    SUM(CASE WHEN fanxiu_1 = 1 THEN 1 ELSE 0 END) AS fanxiu_1,  -- 返修量
    CONCAT(ROUND(SUM(CASE WHEN fanxiu_1 = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT order_no_1), 2), '%') AS fanxiu_rate  -- 返修率
FROM 
    rpt.rpt_wx_fanxiu_quan_mx
WHERE 
    pt = '${-1d_pt}'  -- 最新分区
    AND city_name = '北京市'  -- 北京市
    AND SUBSTR(service_order_complete_time, 1, 7) BETWEEN '2025-01' AND '2025-12'  -- 2025年1月到12月
    AND product_name_1 IS NOT NULL  -- 排除空商品
GROUP BY 
    product_name_1
ORDER BY 
    order_no_1 DESC  -- 按完工单量降序排列
;
