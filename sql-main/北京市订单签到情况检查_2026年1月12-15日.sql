-- 北京市2026年1月12日-15日订单签到情况检查（简化版）
-- 用于检查是否真的有未签到的订单
-- 更新日期：2026-01-16

SELECT 
    SUBSTR(a.order_create_time, 1, 10) AS `订单日期`,
    a.service_order_code AS `服务单编码`,
    a.order_no AS `订单号`,
    a.city_name AS `城市`,
    a.order_type AS `订单类型`,
    a.label_group AS `标签组`,
    a.lease_status AS `租赁状态`,
    a.service_order_supplier_name AS `供应商`,
    a.order_create_time AS `订单创建时间`,
    a.first_sign_time AS `首次签到时间`,
    a.service_start_time AS `预约服务开始时间`,
    CASE 
        WHEN a.first_sign_time IS NOT NULL 
            AND a.first_sign_time != '1000-01-01 00:00:00' 
        THEN '是' 
        ELSE '否' 
    END AS `是否签到`
FROM olap.olap_hj_fas_main_order_service_info_da a
WHERE a.pt = '${-1d_pt}'
    AND a.city_name = '北京市'
    AND SUBSTR(a.order_create_time, 1, 10) BETWEEN '2026-01-12' AND '2026-01-15'
    AND a.order_type = 16  -- 维修订单
ORDER BY 
    a.order_create_time,
    a.first_sign_time
;
