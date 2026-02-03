WITH  house_lease_info AS (
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

-- 获取咨询工单数据
ticket_data AS (
    SELECT 
        ticket_id,
        city_name,
        ctime AS ticket_create_time,
        three_current_name,
        parent_name,
        ticket_status,
        question_desc
    FROM rpt.rpt_trusteeship_private_fuwu_houseout_renter_da 
    WHERE pt = '${-1d_pt}'
        AND parent_name = '维修'  -- 一级分类为维修
        AND ticket_status NOT IN (5, 6)  -- 排除无效单和重复单
        AND three_current_name NOT IN (
            '指定服务者',
            '取消维修订单',
            '表扬维修师傅',
            '维修下单',
            '下单流程咨询',
            '服务范围内收费'
        )  -- 剔除不相关的三级分类
        AND ctime >= '2025-11-01 00:00:00'
        AND ctime < '2027-01-01 00:00:00'
),

-- 通过中间表关联维修单号和咨询工单
relation_data AS (
    SELECT DISTINCT
        ticket_id,
        repair_order
    FROM ods.ods_plat_private_domain_ticket_repair_order_relation_da
    WHERE pt = '${-1d_pt}'
        AND repair_order IS NOT NULL
        AND ticket_id IS NOT NULL
),

-- 拆分多个维修单号
relation_expanded AS (
    SELECT DISTINCT
        ticket_id,
        trim(repair_order_item) AS repair_order
    FROM relation_data
    LATERAL VIEW explode(split(repair_order, ',')) t AS repair_order_item
    WHERE trim(repair_order_item) != ''
),

-- 获取订单商品信息（用于判断订单分类）
order_commodity_info AS (
    SELECT 
        order_no,
        -- 判断订单分类：定损类、漏水类、其他
        CASE 
            WHEN MAX(CASE WHEN commodity_name IN ('夏季空调预检',
                '定损', '漏水定损', '火灾定损', '其他定损',
                '京北漏水定损', '京南漏水定损', '京北火灾定损', '京南火灾定损',
                '京北其他定损', '京南其他定损'
            ) OR commodity_name LIKE '%定损%' THEN 1 ELSE 0 END) = 1 
            THEN '定损类'
            WHEN MAX(CASE WHEN commodity_name LIKE '%漏水%' OR commodity_name = '漏水专项检修' THEN 1 ELSE 0 END) = 1 
            THEN '漏水类'
            ELSE '其他'
        END AS order_category
    FROM olap.olap_hj_fas_main_order_commodity_da
    WHERE pt = '${-1d_pt}'
        AND commodity_type = 1  -- 下单商品
    GROUP BY order_no
)

insert overwrite table rpt.rpt_on_time_rate partition (pt='${-1d_pt}')


SELECT DISTINCT
    -- 1. 考核月份
    SUBSTR(a.order_create_time, 1, 7) AS `创建月份`,
    
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
    COALESCE(oci.order_category, '其他') AS `订单分类`,

    -- 10.房源id
    a.house_resource_id,
    
    -- 10. 紧急单/普通单
    CASE 
        WHEN a.performance_mode=1 THEN '紧急单'
        ELSE '普通单'
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
    
    -- 14. 取消单是否剔除（剔除逻辑：夜间取消单、白天致电前取消、紧急单30分钟内取消、普通单1小时内取消）
    CASE 
        WHEN a.order_status = 50 
             AND a.cancel_time IS NOT NULL 
             AND a.cancel_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
        THEN
            CASE 
                -- 夜间取消（21点-次日9点）
                WHEN (SUBSTR(a.cancel_time, 12, 2) >= '21' AND SUBSTR(a.cancel_time, 12, 2) <= '23')
                     OR (SUBSTR(a.cancel_time, 12, 2) >= '00' AND SUBSTR(a.cancel_time, 12, 2) < '09')
                THEN '是'
                -- 白天致电前取消
                WHEN (a.first_call_time IS NULL 
                      OR a.first_call_time = '1000-01-01 00:00:00' 
                      OR SUBSTR(a.first_call_time, 1, 4) < '2000')
                     OR (SUBSTR(a.first_call_time, 1, 4) >= '2000' AND a.cancel_time < a.first_call_time)
                THEN '是'
                -- 紧急单30分钟内取消
                WHEN a.performance_mode =1
                     AND (UNIX_TIMESTAMP(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                          - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 30
                THEN '是'
                -- 普通单1小时内取消
                WHEN (a.performance_mode!=1)
                     AND (UNIX_TIMESTAMP(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                          - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60
                THEN '是'
                ELSE '否'
            END
        ELSE '否'
    END AS `取消单是否剔除`,
    
    -- 15. 取消单剔除原因
    CASE 
        WHEN a.order_status = 50 
             AND a.cancel_time IS NOT NULL 
             AND a.cancel_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.cancel_time, 1, 4) >= '2000'
        THEN
            CASE 
                -- 夜间取消（21点-次日9点）
                WHEN (SUBSTR(a.cancel_time, 12, 2) >= '21' AND SUBSTR(a.cancel_time, 12, 2) <= '23')
                     OR (SUBSTR(a.cancel_time, 12, 2) >= '00' AND SUBSTR(a.cancel_time, 12, 2) < '09')
                THEN '夜间取消单'
                -- 白天致电前取消
                WHEN (a.first_call_time IS NULL 
                      OR a.first_call_time = '1000-01-01 00:00:00' 
                      OR SUBSTR(a.first_call_time, 1, 4) < '2000')
                     OR (SUBSTR(a.first_call_time, 1, 4) >= '2000' AND a.cancel_time < a.first_call_time)
                THEN '白天致电前取消'
                -- 紧急单30分钟内取消
                WHEN a.performance_mode IN (1)
                     AND (UNIX_TIMESTAMP(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                          - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 30
                THEN '紧急单30分钟内取消'
                -- 普通单1小时内取消
                WHEN (a.performance_mode != 1)
                     AND (UNIX_TIMESTAMP(a.cancel_time, 'yyyy-MM-dd HH:mm:ss')
                          - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 60
                THEN '普通单1小时内取消'
                ELSE NULL
            END
        ELSE NULL
    END AS `取消单剔除原因`,
    
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
        WHEN a.performance_mode!=1 THEN
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
        WHEN (a.performance_mode != 1 )
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
    END AS `普通单上门时间`,
    
    -- 23. 普通单是否及时上门（首次签到时间小于考核时间的就是是）
    CASE 
    -- 先剔除：如果是“普通单”且满足“未联系就取消”的条件，直接判为 NULL
    WHEN a.performance_mode!= 1
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
    WHEN a.performance_mode != 1
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
        WHEN a.performance_mode IN (1) THEN a.order_create_time
        ELSE NULL
    END AS `紧急单考核时间`,
    
    -- 25. 紧急单是否2h上门
    CASE 
        WHEN a.performance_mode IN (1)
             AND a.first_sign_time IS NOT NULL
             AND a.first_sign_time != '1000-01-01 00:00:00'
             AND SUBSTR(a.first_sign_time, 1, 4) >= '2000'
        THEN
            CASE 
                WHEN (UNIX_TIMESTAMP(a.first_sign_time, 'yyyy-MM-dd HH:mm:ss') 
                      - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 <= 120
                THEN '是'
                ELSE '否'
            END
        ELSE NULL
    END AS `紧急单是否2h上门`,
    
    -- 26. 是否维修咨询订单（剔除咨询非师傅问题）
    CASE 
        WHEN consult_ticket.ticket_id IS NOT NULL THEN '是'
        ELSE '否'
    END AS `是否维修咨询订单`,
    a.service_end_time as `预约结束时间`

FROM olap.olap_hj_fas_main_order_service_info_da a

-- 关联订单商品信息（用于判断订单分类）
LEFT JOIN order_commodity_info oci
    ON a.order_no = oci.order_no

-- 关联咨询工单数据
LEFT JOIN relation_expanded consult_relation
    ON a.order_no = consult_relation.repair_order
LEFT JOIN ticket_data consult_ticket
    ON consult_relation.ticket_id = consult_ticket.ticket_id
LEFT JOIN house_lease_info house on a.house_resource_id=house.house_code
WHERE a.pt = '${-1d_pt}'
    AND a.order_type = 16  -- 维修订单
    AND a.label_group != '8'  -- 剔除门锁订单
    AND a.vison_type = '4.0'
    AND a.supplier_name NOT IN (
            '上海兰宫建筑装饰有限公司',
            '上海尚礼实业有限公司',
            '上海苏皖贸易有限公司',
            '上海再旭保洁服务有限公司',
            '源和里仁家具海安有限公司',
            '匠云（北京）科技有限公司'
        )