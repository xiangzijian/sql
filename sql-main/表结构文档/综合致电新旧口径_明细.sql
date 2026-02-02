-- 综合致电新旧口径 - 明细查询
-- 统计范围：宁波市，2025年11月
-- 用于核对数据，包含是否紧急单、是否剔除、剔除原因等信息

SELECT
    a.order_no AS `订单号`,
    a.order_create_time AS `下单时间`,
    a.cancel_time AS `取消时间`,
    a.first_call_time AS `首次致电时间`,
    a.service_order_complete_time AS `完工时间`,
    a.city_name AS `城市`,
    a.label_group AS `标签组`,
    a.lease_status AS `租赁状态`,
    
    -- 判断是否紧急单
    CASE 
        WHEN kk.`总订单` IS NOT NULL THEN '是'
        ELSE '否'
    END AS `是否紧急单`,
    
    -- 紧急单相关信息
    CASE 
        WHEN kk.`紧急30分钟致电单` IS NOT NULL THEN '是'
        ELSE '否'
    END AS `是否30分钟内致电(紧急单)`,
    
    -- 非紧急单：1小时首联判断
    CASE 
        WHEN kk.`总订单` IS NULL THEN
            CASE 
                WHEN a.is_not = 1 THEN '是'
                WHEN substr(a.first_call_time, 1, 4) >= '2000'
                    AND (unix_timestamp(a.first_call_time, 'yyyy-MM-dd HH:mm:ss')
                         - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60 
                THEN '是'
                ELSE '否'
            END
        ELSE NULL
    END AS `是否1小时首联(非紧急单)`,
    
    -- 取消时长（分钟）
    CASE 
        WHEN a.cancel_time != '1000-01-01 00:00:00' 
        THEN CAST((unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                   - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 AS INT)
        ELSE NULL
    END AS `下单到取消时长(分钟)`,
    
    -- 致电时长（分钟）
    CASE 
        WHEN substr(a.first_call_time, 1, 4) >= '2000' 
        THEN CAST((unix_timestamp(a.first_call_time, 'yyyy-MM-dd HH:mm:ss')
                   - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 AS INT)
        ELSE NULL
    END AS `下单到首次致电时长(分钟)`,
    
    -- 取消时间小时段
    CASE 
        WHEN a.cancel_time != '1000-01-01 00:00:00' 
        THEN substr(a.cancel_time, 12, 2)
        ELSE NULL
    END AS `取消时间(小时)`,
    
    -- ==================== 新口径剔除判断 ====================
    
    -- 对于非紧急单，判断是否在新口径中被剔除
    CASE 
        WHEN kk.`总订单` IS NULL THEN  -- 非紧急单
            CASE 
                -- 判断是否被剔除
                WHEN a.cancel_time != '1000-01-01 00:00:00'
                    AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                         - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60
                THEN '是'
                WHEN a.cancel_time != '1000-01-01 00:00:00'
                    AND ((substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                         OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09'))
                THEN '是'
                ELSE '否'
            END
        ELSE NULL
    END AS `是否剔除(非紧急单-新口径)`,
    
    -- 对于紧急单，判断是否在新口径中被剔除
    CASE 
        WHEN kk.`总订单` IS NOT NULL THEN  -- 紧急单
            CASE 
                -- 判断是否被剔除
                WHEN a.cancel_time != '1000-01-01 00:00:00'
                    AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                         - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 30
                THEN '是'
                WHEN a.cancel_time != '1000-01-01 00:00:00'
                    AND ((substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                         OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09'))
                THEN '是'
                ELSE '否'
            END
        ELSE NULL
    END AS `是否剔除(紧急单-新口径)`,
    
    -- 剔除原因（非紧急单）
    CASE 
        WHEN kk.`总订单` IS NULL THEN  -- 非紧急单
            CASE 
                WHEN a.cancel_time != '1000-01-01 00:00:00'
                    AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                         - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60
                    AND ((substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                         OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09'))
                THEN '下单1小时内取消 + 夜间21-9点取消'
                WHEN a.cancel_time != '1000-01-01 00:00:00'
                    AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                         - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60
                THEN '下单1小时内取消'
                WHEN a.cancel_time != '1000-01-01 00:00:00'
                    AND ((substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                         OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09'))
                THEN '夜间21-9点取消'
                ELSE NULL
            END
        ELSE NULL
    END AS `剔除原因(非紧急单-新口径)`,
    
    -- 剔除原因（紧急单）
    CASE 
        WHEN kk.`总订单` IS NOT NULL THEN  -- 紧急单
            CASE 
                WHEN a.cancel_time != '1000-01-01 00:00:00'
                    AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                         - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 30
                    AND ((substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                         OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09'))
                THEN '下单30分钟内取消 + 夜间21-9点取消'
                WHEN a.cancel_time != '1000-01-01 00:00:00'
                    AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                         - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 30
                THEN '下单30分钟内取消'
                WHEN a.cancel_time != '1000-01-01 00:00:00'
                    AND ((substr(a.cancel_time, 12, 2) >= '21' AND substr(a.cancel_time, 12, 2) <= '23')
                         OR (substr(a.cancel_time, 12, 2) >= '00' AND substr(a.cancel_time, 12, 2) < '09'))
                THEN '夜间21-9点取消'
                ELSE NULL
            END
        ELSE NULL
    END AS `剔除原因(紧急单-新口径)`,
    
    -- ==================== 旧口径剔除判断 ====================
    
    -- 旧口径是否剔除（统一标准：1小时或60分钟内取消）
    CASE 
        WHEN a.cancel_time != '1000-01-01 00:00:00'
            AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                 - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60
        THEN '是'
        ELSE '否'
    END AS `是否剔除(旧口径)`,
    
    -- 旧口径剔除原因
    CASE 
        WHEN a.cancel_time != '1000-01-01 00:00:00'
            AND (unix_timestamp(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                 - unix_timestamp(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60
        THEN '下单1小时(60分钟)内取消'
        ELSE NULL
    END AS `剔除原因(旧口径)`,
    
    -- 服务者取消角色（从订单服务信息表获取）
    a.cancel_role AS `服务者取消角色`,
    a.cancel_reason AS `取消原因`,
    
    -- 其他辅助字段
    kk.urgent_flag AS `紧急标识`,
    kk.performance_mode AS `履约模式`

FROM (
    SELECT DISTINCT
        a.order_no,
        a.order_create_time,
        a.service_order_complete_time,
        a.first_call_time,
        a.cancel_time,
        a.label_group,
        a.lease_status,
        a.cancel_role,
        a.cancel_reason,
        CASE
            WHEN substr(a.order_create_time, 12, 2) >= '21'
               AND a.first_call_time < concat(date_add(to_date(a.order_create_time), 1), ' 10:00:00')
               AND substr(a.first_call_time, 1, 4) >= '2000'
            THEN 1
            WHEN substr(a.order_create_time, 12, 2) < '09'
               AND a.first_call_time < concat(to_date(a.order_create_time), ' 10:00:00')
               AND substr(a.first_call_time, 1, 4) >= '2000'
            THEN 1
            ELSE 0
        END AS is_not,
        a.city_name
    FROM olap.olap_hj_fas_main_order_service_info_da a
    INNER JOIN (
        SELECT DISTINCT order_no AS oth_orderno
        FROM rpt.rpt_fas_light_hosting_order_detail_da
        WHERE pt = '20260110000000'
        AND vison_type = '4.0'
        AND service_name IN ('维修','燃气')
        AND order_type = '16'
        AND label_group NOT IN ('8')
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
    ) b ON b.oth_orderno = a.order_no
    WHERE a.pt = '20260110000000'
    AND a.order_type = 16
    AND a.label_group NOT IN ('1', '8','25')
    AND a.lease_status IN (2, 3)
    AND a.city_name = '宁波市'
    AND SUBSTR(a.order_create_time, 1, 7) = '2025-11'
) a

-- 关联紧急单数据
LEFT JOIN (
    SELECT DISTINCT
        order_create_time,
        order_no as order_no_1,
        case when city_name = '北京市' then manager_corp_name else city_name end as city_name,
        urgent_flag,
        performance_mode,
        CASE WHEN is_urgent_order = 1 OR is_urgent_switch = 1 THEN order_no END as `总订单`,
        case when is_30_min_urgent_call = 1 and (is_urgent_order = 1 OR is_urgent_switch = 1) then order_no END as `紧急30分钟致电单`
    FROM rpt.rpt_jiafu_urgent_order_info_da
    WHERE pt = '20260110000000'
    AND substr(order_create_time, 1, 7) = '2025-11'
    AND (urgent_flag in (1, 2) or performance_mode in (1, 2))
    AND case when city_name = '北京市' then manager_corp_name else city_name end = '宁波市'
) kk ON kk.order_no_1 = a.order_no

ORDER BY 
    CASE WHEN kk.`总订单` IS NOT NULL THEN 1 ELSE 2 END,  -- 紧急单排在前面
    a.order_create_time;
