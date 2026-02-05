--模板查询：新-明细1
WITH  
base_data AS (
    SELECT order_no,order_create_time,city_name,bizcircle_name,
    service_order_supplier_name,service_order_professional_name,
    service_order_professional_ucid,house_resource_id,max(service_order_complete_time) as service_order_complete_time
    ,max(service_start_time) as service_start_time
    ,max(label_group) as label_group
    ,max(lease_status) as lease_status
    ,max(order_status) as order_status
    ,max(cancel_time) as cancel_time
    ,max(first_call_time) as first_call_time
    ,max(service_end_time) as service_end_time
    ,max(first_sign_time) as first_sign_time
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${-1d_pt}'
    AND order_type = 16  -- 维修订单
    AND label_group != '8'  -- 剔除门锁订单
    group by order_no,order_create_time,city_name,bizcircle_name,service_order_supplier_name
    ,service_order_professional_name,service_order_professional_ucid,house_resource_id
) 
,
house_lease_info AS (
    SELECT 
        house_code,
        max(effective_start_date)  AS lease_start_date  -- 合同起租日
    FROM rpt.rpt_plat_manager_workbench_manager_task_da
    WHERE pt = '${-1d_pt}'  
        AND effective_start_date IS NOT NULL
        AND effective_start_date != '1000-01-01 00:00:00'
        AND SUBSTR(effective_start_date, 1, 7) >= '2025-05' 
        group by house_code
),

kk as (
        SELECT DISTINCT
        order_create_time,
        order_no as order_no_1,
        case when city_name = '北京市' then manager_corp_name else city_name end as city_name,
        CASE WHEN is_urgent_order = 1 OR is_urgent_switch = 1 THEN order_no END as `总订单`,
        case when is_30_min_urgent_call = 1 and (is_urgent_order = 1 OR is_urgent_switch = 1) then order_no END as `紧急30分钟致电单`
    FROM rpt.rpt_jiafu_urgent_order_info_da
    WHERE pt = '${-1d_pt}'
    AND substr(order_create_time, 1, 7) >= '2025-06'
    AND (urgent_flag in (1, 2) or performance_mode in (1))
)


insert overwrite table rpt.rpt_on_time_rate partition (pt='${-1d_pt}')


SELECT DISTINCT
    -- 1. 考核月份
    SUBSTR(a.order_create_time, 1, 7) AS `订单创建月份`,
    
    -- 2. 订单创建时间
    a.order_create_time AS `订单创建时间`,
    
    -- 3. 城市
    a.city_name AS `城市`,
    
    -- 4. 商圈
    COALESCE(a.bizcircle_name, '') AS `商圈`,
    
    -- 5. 供应商
    COALESCE(a.service_order_supplier_name, '待分配') AS `供应商`,
    
    -- 6. 服务者
    COALESCE(a.service_order_professional_name, '') AS `服务者`,
    
    -- 7. 服务者id
    COALESCE(a.service_order_professional_ucid, '') AS `服务者ID`,
    
    -- 8. 维修订单号
    a.order_no AS `维修订单号`,
    
    -- 9. 订单分类（定损类、漏水类、其他）
     CASE WHEN CASE WHEN b.commodity_name_list1 IN ('夏季空调预检',
                '定损', '漏水定损', '火灾定损', '其他定损',
                '京北漏水定损', '京南漏水定损', '京北火灾定损', '京南火灾定损',
                '京北其他定损', '京南其他定损'
            ) THEN 1 ELSE 0 END = 1 
            THEN '定损类'
            WHEN CASE WHEN  b.commodity_name_list1 in ( '漏水专项检修','SCM00300001672373','消防器材') THEN 1 ELSE 0 END = 1 
            THEN '漏水类'
            ELSE '其他'
    END AS `订单分类`,

    -- 10.房源id
    a.house_resource_id,
    
    -- 10. 紧急单/普通单
    CASE 
        WHEN kk.`总订单` IS NULL THEN '普通单'
        ELSE '紧急单'
    END AS `紧急单/普通单`,
    -- 11.完工时间
    a.service_order_complete_time,
    -- 12.房源最新出租时间
    house.lease_start_date,
    -- 13.预约开始时间
    a.service_start_time,
    -- 11. 租后维修/检修
    CASE 
        WHEN a.label_group NOT IN ('1', '8', '25') AND a.lease_status IN (2, 3) THEN '租后维修'
        WHEN (a.label_group IN ('1', '25') OR a.lease_status IN ('-1', '1')) THEN '检修'
        ELSE '其他'
    END AS `租后维修/检修`,
    
    -- 12. 是否取消（order_status = 50）
    CASE 
        WHEN a.order_status = 50 THEN '是'
        ELSE '否'
    END AS `是否取消`,
    
    -- 13. 取消时间
    CASE 
        WHEN a.cancel_time IS NOT NULL 
             AND a.cancel_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
        THEN a.cancel_time
        ELSE NULL
    END AS `取消时间`,
    
    CASE 
        WHEN a.order_status = 50 
             AND a.cancel_time IS NOT NULL 
             AND a.cancel_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
             AND ((SUBSTR(a.cancel_time, 12, 2) >= '21' AND SUBSTR(a.cancel_time, 12, 2) <= '23')
              OR (SUBSTR(a.cancel_time, 12, 2) >= '00' AND SUBSTR(a.cancel_time, 12, 2) < '09') )
        THEN 1
        ELSE 0  
    END AS `是否夜间取消`,
    CASE 
        WHEN a.order_status = 50 
             AND a.cancel_time IS NOT NULL 
             AND a.cancel_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
             AND ((a.first_call_time IS NULL 
                      OR a.first_call_time = '1000-01-01 00:00:00' 
                      OR SUBSTR(a.first_call_time, 1, 4) < '2000')
                     OR (SUBSTR(a.first_call_time, 1, 4) >= '2000' AND a.cancel_time < a.first_call_time))
        THEN 1
        ELSE 0  
    END AS `是否白天致电前取消`,
    CASE 
        WHEN a.order_status = 50 
             AND a.cancel_time IS NOT NULL 
             AND a.cancel_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
             AND kk.`总订单` IS not NULL 
             AND (UNIX_TIMESTAMP(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')- UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 30
        THEN 1
        ELSE 0  
    END AS `是否紧急单30分钟内取消`,

    CASE 
        WHEN a.order_status = 50 
             AND a.cancel_time IS NOT NULL 
             AND a.cancel_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
             AND kk.`总订单` IS NULL 
             AND (UNIX_TIMESTAMP(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                  - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60
        THEN 1
        ELSE 0  
    END AS `是否普通单1小时内取消`,

    -- 16. 首次致电时间
    CASE 
        WHEN a.first_call_time IS NOT NULL 
             AND a.first_call_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.first_call_time, 1, 4) >= '2000'
        THEN a.first_call_time
        ELSE NULL
    END AS `首次致电时间`,
    
    -- 17. 是否30分钟内致电
    CASE 
        WHEN a.first_call_time IS NOT NULL 
             AND a.first_call_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.first_call_time, 1, 4) >= '2000'
             AND (UNIX_TIMESTAMP(a.first_call_time, 'yyyy-MM-dd HH:mm:ss')
                  - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 30
        THEN '是'
        ELSE '否'
    END AS `是否30分钟内致电`,
    
    -- 18. 是否1小时内致电
    CASE 
        WHEN a.first_call_time IS NOT NULL 
             AND a.first_call_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.first_call_time, 1, 4) >= '2000'
             AND (UNIX_TIMESTAMP(a.first_call_time, 'yyyy-MM-dd HH:mm:ss')
                  - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60
        THEN '是'
        --夜间逻辑
        WHEN substr(a.order_create_time, 12, 2) >= '21'
             AND a.first_call_time < concat(date_add(to_date(a.order_create_time), 1), ' 10:00:00')
             AND substr(a.first_call_time, 1, 4) >= '2000'
        THEN '是'
        WHEN substr(a.order_create_time, 12, 2) < '09'
             AND a.first_call_time < concat(to_date(a.order_create_time), ' 10:00:00')
             AND substr(a.first_call_time, 1, 4) >= '2000'
         THEN '是'
        ELSE '否'
    END AS `是否1小时内致电`,
    
    -- 19. 普通单及时上门考核时间（客户下单首次预约结束时间或未致电客户改约时间）
    CASE 
        WHEN kk.`总订单` IS NULL THEN
            CASE 
                -- 优先使用预约服务结束时间
                WHEN a.service_end_time IS NOT NULL 
                     AND SUBSTR(a.service_end_time, 1, 4) >= '2000'
                THEN a.service_end_time
                ELSE NULL
            END
        ELSE NULL
    END AS `普通单及时上门考核时间`,
    
    -- 20. 是否首次致电前取消
    CASE 
        WHEN a.order_status = 50 
             AND a.cancel_time IS NOT NULL 
             AND a.cancel_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
        THEN
            CASE 
                -- 情况1：没有致电时间（首次致电前取消）
                WHEN a.first_call_time IS NULL 
                     OR a.first_call_time = '1000-01-01 00:00:00' 
                     OR SUBSTR(a.first_call_time, 1, 4) < '2000'
                THEN '是'
                -- 情况2：有致电时间，但取消时间在致电时间之前（首次致电前取消）
                WHEN SUBSTR(a.first_call_time, 1, 4) >= '2000'
                     AND a.cancel_time < a.first_call_time
                THEN '是'
                ELSE '否'
            END
        ELSE '否'
    END AS `是否首次致电前取消`,
    
    -- 21. 首次签到时间
    CASE 
        WHEN a.first_sign_time IS NOT NULL 
             AND a.first_sign_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.first_sign_time, 1, 4) >= '2000'
        THEN a.first_sign_time
        ELSE NULL
    END AS `首次签到时间`,
    
    -- 22. 普通单上门时间（首次签到时间-上门考核时间（h））
    CASE 
        WHEN kk.`总订单` IS NULL 
             AND a.first_sign_time IS NOT NULL 
             AND a.first_sign_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.first_sign_time, 1, 4) >= '2000'
        THEN
            CASE 
                -- 使用预约服务结束时间作为考核时间
                WHEN a.service_end_time IS NOT NULL 
                     AND SUBSTR(a.service_end_time, 1, 4) >= '2000'
                THEN ROUND((UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss')
                           - UNIX_TIMESTAMP(a.service_end_time, 'yyyy-MM-dd HH:mm:ss')) / 3600, 2)
                ELSE NULL
            END
        ELSE NULL
    END AS `普通单上门时长`,
    
    -- 23. 普通单是否及时上门（首次签到时间小于考核时间的就是是）
    CASE 
    -- 先剔除：如果是“普通单”且满足“未联系就取消”的条件，直接判为 NULL
    WHEN kk.`总订单` IS NULL 
         AND a.order_status = 50 
         AND a.cancel_time != '1000-01-01 00:00:00'
         AND (
             -- 未联系过客户
             (a.first_call_time IS NULL OR a.first_call_time = '1000-01-01 00:00:00' OR SUBSTR(a.first_call_time, 1, 4) < '2000')
             OR
             -- 或者 取消时间 < 联系时间
             (SUBSTR(a.first_call_time, 1, 4) >= '2000' AND a.cancel_time < a.first_call_time)
         )
    THEN NULL -- 这里的 NULL 表示剔除，不计入分子分母
    WHEN kk.`总订单` IS NULL 
         AND a.first_sign_time IS NOT NULL 
         AND a.first_sign_time != '1000-01-01 00:00:00'
         AND SUBSTR(a.first_sign_time, 1, 4) >= '2000'
         and a.service_end_time IS NOT NULL
        AND a.first_sign_time <= a.service_end_time
    THEN '是'
    ELSE NULL
    END AS `普通单是否及时上门`,
    
    -- 24. 紧急单考核时间（紧急单的创建时间）
    CASE 
        WHEN kk.`总订单` IS not NULL THEN a.order_create_time
        ELSE NULL
    END AS `紧急单考核时间`,
    
    -- 25. 紧急单是否2h上门
     CASE 
        WHEN kk.`总订单` IS not NULL 
             AND a.first_sign_time IS NOT NULL
             AND a.first_sign_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.first_sign_time, 1, 4) >= '2000'
             AND (UNIX_TIMESTAMP(a.first_sign_time) 
                      - UNIX_TIMESTAMP(a.order_create_time)) / 60 <= 120
             THEN '是'
             ELSE '否'
            END
     AS `紧急单是否2h上门`,

    CASE 
    WHEN service_order_complete_time IS NULL 
      OR service_order_complete_time = '1000-01-01 00:00:00' 
    THEN 0 
    WHEN first_sign_time IS NOT NULL 
      AND first_sign_time != '1000-01-01 00:00:00' 
      AND first_sign_time < service_end_time 
    THEN 
        CASE 
            WHEN (unix_timestamp(service_order_complete_time) - unix_timestamp(first_sign_time)) / 3600.0 <= 24 
            THEN 1 ELSE 0 
        END
    ELSE 
        CASE 
            WHEN (unix_timestamp(service_order_complete_time) - unix_timestamp(service_end_time)) / 3600.0 <= 24 
            THEN 1 ELSE 0 
        END
    END 
    as `租后是否及时完工`,
	CASE 
    WHEN a.service_order_complete_time IS NOT NULL 
     AND a.service_order_complete_time != '1000-01-01 00:00:00' 
     AND (
        -- 1. 48小时内
        (unix_timestamp(a.service_order_complete_time) - unix_timestamp(a.order_create_time)) / 3600.0 <= 48
        OR 
        -- 2. 7天内 AND (无起租 OR 起租不在检修期间)
        (
            (unix_timestamp(a.service_order_complete_time) - unix_timestamp(a.order_create_time)) / 3600.0 <= 168
            AND NOT (
                house.lease_start_date IS NOT NULL 
                AND house.lease_start_date >= SUBSTR(a.order_create_time, 1, 10)
                AND house.lease_start_date <= SUBSTR(a.service_order_complete_time, 1, 10)
            )
        )
     )
    THEN 1 
    ELSE 0 
    END AS `检修是否及时完工`,
    a.service_end_time as `预约结束时间`
FROM  base_data a
INNER JOIN (
        SELECT DISTINCT order_no AS oth_orderno,
        commodity_name_list1
        FROM rpt.rpt_fas_light_hosting_order_detail_da
        WHERE pt = '${-1d_pt}'
        AND vison_type = '4.0'
        AND service_name IN ('维修','燃气')
        AND order_type = '16'
        AND label_group NOT IN ('8')
        AND supplier_name NOT IN (
            '上海兰宫建筑装饰有限公司',
            '上海尚礼实业有限公司',
            '上海苏皖贸易有限公司',
            '上海再旭保洁服务有限公司',
            '源和里仁家具海安有限公司',
            '匠云（北京）科技有限公司'
        )
      AND commodity_name_list1 NOT IN (
            '夏季空调预检', 'SCM00300001672373', '漏水专项检修','消防器材', '定损', '漏水定损','火灾定损','其他定损', '京北漏水定损', '京南漏水定损','京北火灾定损', '京南火灾定损',
            '京北其他定损', '京南其他定损')
    ) b ON b.oth_orderno = a.order_no
-- 关联紧急单数据
left join kk on kk.order_no_1 = a.order_no
LEFT JOIN house_lease_info house on a.house_resource_id=house.house_code