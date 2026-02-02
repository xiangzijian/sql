WITH t1 AS (
    SELECT 
        SUBSTR(ctime, 1, 7) AS month,
        ctime,
        city_name AS `城市名称`, 
        ticket_id, 
        three_current_name,
        question_desc AS `问题描述`
    FROM rpt.rpt_trusteeship_private_fuwu_houseout_renter_da 
    WHERE  
        pt = '20251216000000'
        AND mood = '负向'
        AND ctime >= '2025-01-01 00:00:00' 
        AND parent_name = '维修'
        AND SUBSTR(ctime, 1, 10) BETWEEN '2025-10-01' AND '2025-10-31'
        AND ticket_status NOT IN (5, 6)
        AND three_current_name IN (
            '加急维修订单','更换服务者','没修好就关单','维修多次没修好','维修上门时间确认',
            '维修师傅迟到爽约',
            '维修无人二次跟进',
            '维修师傅电话确认',
            '下单后无人联系',
            '换新无人跟进&催促解决','未带配件/工具'
        )
),

t2 AS (
    SELECT 
        SUBSTR(r2.order_create_time, 1, 7) AS month,
        r2.order_create_time,
        r2.city_name,
        order_no,
        service_order_professional_name,
        service_order_supplier_name
    FROM olap.olap_hj_fas_main_order_service_info_da r2
    WHERE  
        r2.pt = '20251216000000'
        AND r2.service_code = '10003'
        AND r2.order_type = '16'
        AND r2.label_group NOT IN ('1', '8', '25', '13', '21')
        AND r2.lease_status IN ('2', '3')
        AND r2.order_create_time >= '2025-01-01 00:00:00' 
       --  AND r2.service_order_supplier_name != '上海祥呈建设工程有限公司'
),

t3 AS (
    SELECT
        order_no,
        commodity_name
    FROM olap.olap_hj_fas_main_order_commodity_da
    WHERE pt = '20251216000000' 
      AND commodity_type = 1 
),

c AS (
    SELECT DISTINCT
        ticket_id, 
        e.repair_order 
    FROM ods.ods_plat_private_domain_ticket_repair_order_relation_da t
    LATERAL VIEW explode(split(repair_order, ',')) e AS repair_order
    WHERE t.repair_order IS NOT NULL 
      AND e.repair_order IS NOT NULL  
      AND t.pt = '20251216000000'
),


keyword_map AS (
    SELECT 
        trim(regexp_replace(c2, '\\s+', '')) AS standard_commodity,
        trim(regexp_replace(keyword_raw, '[\\s\\u00A0\\u3000]+', '')) AS keyword
    FROM odin.t_excel_guanlian_biao
    LATERAL VIEW explode(split(regexp_replace(c3, '、', ','), ',')) t AS keyword_raw
    WHERE c2 IS NOT NULL 
      AND c3 IS NOT NULL
      AND trim(keyword_raw) != ''
),

-- 原始聚合
base_aggregated AS (
    SELECT 
        COALESCE(t1.month, t2.month) AS `月份`,
        COALESCE(t1.`城市名称`, t2.city_name) AS `城市`,
        t2.service_order_supplier_name AS `供应商`,
        t2.service_order_professional_name AS `服务者`,
        t1.three_current_name AS `维修分类`,
        t2.order_no,
        CONCAT_WS(',', COLLECT_LIST(t3.commodity_name)) AS all_commodities,
        t1.ticket_id,
        t1.`问题描述`
    FROM t2 
    INNER JOIN c ON t2.order_no = c.repair_order 
    INNER JOIN t1 ON t1.ticket_id = c.ticket_id
    INNER JOIN t3 ON t3.order_no = t2.order_no
    WHERE COALESCE(t1.`城市名称`, t2.city_name) = '成都市'
      AND t2.order_create_time > t1.ctime
    GROUP BY 
        COALESCE(t1.month, t2.month),
        COALESCE(t1.`城市名称`, t2.city_name),
        t2.service_order_supplier_name,
        t2.service_order_professional_name,
        t1.three_current_name,
        t2.order_no,
        t1.ticket_id,
        t1.`问题描述`
),

-- ✅ 拆分 all_commodities 并清洗商品名
expanded_with_match AS (
    SELECT 
        b.*,
        trim(regexp_replace(commodity_item, '\\s+', '')) AS single_commodity_clean
    FROM base_aggregated b
    LATERAL VIEW explode(split(b.all_commodities, ',')) t AS commodity_item
    WHERE trim(commodity_item) != ''
),

-- ✅ 关联关键词（用清洗后的商品名） + 提前计算问题关键词命中
final_with_match AS (
    SELECT 
        `月份`,
        `城市`,
        `供应商`,
        `服务者`,
        `维修分类`,
        order_no,
        all_commodities,
        ticket_id,
        `问题描述`,
        CASE 
            WHEN km.keyword IS NOT NULL 
             AND LOWER(`问题描述`) LIKE CONCAT('%', LOWER(km.keyword), '%')
            THEN 1 
            ELSE 0 
        END AS is_match,
        CASE 
            WHEN LOWER(`问题描述`) RLIKE 
                '又复发|没有修好|多次维修|联系不上|推迟|没消息|态度恶劣|态度不好|维修多次|上次维修|上次报修|上次未处理|多次未处理|无人上门|师傅未到|无人联系|前几天修过|未上门|换师傅|未能解决|未修好|维修过|未解决|'
            THEN 1 
            ELSE 0 
        END AS has_problem_keyword
    FROM expanded_with_match e
    LEFT JOIN keyword_map km 
        ON e.single_commodity_clean = km.standard_commodity
)


SELECT 
    `月份`,
    `城市`,
    `供应商`,
    `服务者`,
    `维修分类`,
    order_no,
    all_commodities,
    ticket_id,
    `问题描述`,
    CASE 
        WHEN MAX(is_match) = 1 OR MAX(has_problem_keyword) = 1 THEN 1
        ELSE 0
    END AS is_valid_negative
FROM final_with_match
GROUP BY 
    `月份`,
    `城市`,
    `供应商`,
    `服务者`,
    `维修分类`,
    order_no,
    all_commodities,
    ticket_id,
    `问题描述`
