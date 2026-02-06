--模板查询：万房咨询-城市
-- 咨询工单统计：按月按城市按商圈
-- 统计2025年6月到2026年1月的咨询工单数（分子）和考核在管（分母）
-- 分子：符合特定条件的咨询工单数
-- 分母：考核在管房源数

WITH
-- 1. 咨询工单数据（分子）- 按月份、城市、商圈统计
consultation_tickets AS (
    SELECT
        CONCAT_WS('-', SUBSTR(ctime, 1, 4), SUBSTR(ctime, 6, 2)) AS month_string,
        city_name,
        COALESCE(bizcircle_name, '') AS bizcircle_name,  -- 商圈，空值处理为空字符串
        COUNT(DISTINCT ticket_id) AS consultation_count  -- 咨询工单数
    FROM
        rpt.rpt_trusteeship_private_fuwu_houseout_renter_da
    WHERE
        pt >= '20250601000000' 
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
        AND ctime >= '2025-06-01 00:00:00'
    GROUP BY
        CONCAT_WS('-', SUBSTR(ctime, 1, 4), SUBSTR(ctime, 6, 2)),
        city_name,
        COALESCE(bizcircle_name, '')
),

-- 2. 考核在管数据（分母）- 按月份、城市、商圈统计
manager_data AS (
    SELECT
        CONCAT_WS('-', SUBSTR(pt, 1, 4), SUBSTR(pt, 5, 2)) AS month_string,
        city_name,
        COALESCE(bizcircle_name, '') AS bizcircle_name,  -- 商圈，空值处理为空字符串
        CASE 
            WHEN pt >= '20250401000000' 
            THEN NVL(house_cnt, 0) - NVL(uncensor_house_cnt, 0) - NVL(unstart_house_cnt, 0) 
                 - NVL(cur_seek_expire_unhouseout_cnt, 0) - NVL(cur_0507erchu_seek_expire_unhouseout_cnt, 0) 
            ELSE NVL(house_cnt, 0) - NVL(cur_seek_expire_unhouseout_cnt, 0) 
                 - NVL(cur_0507erchu_seek_expire_unhouseout_cnt, 0)
        END AS house_kaohe_cnt  -- 考核在管
    FROM
        (
            SELECT
                pt,
                city_name,
                COALESCE(bizcircle_name, '') AS bizcircle_name,  -- 商圈
                COUNT(DISTINCT CONCAT(CAST(trusteeship_housedel_code AS STRING), CAST(housedel_id AS STRING))) AS house_cnt,  -- 当前库存签约在管房源量
                COUNT(DISTINCT CASE 
                    WHEN hin_type = 3 
                    THEN CONCAT(CAST(trusteeship_housedel_code AS STRING), CAST(housedel_id AS STRING))
                    ELSE NULL 
                END) AS uncensor_house_cnt,  -- 已开始招租但未审核通过房源量
                COUNT(DISTINCT CASE 
                    WHEN hin_type = 4 
                    THEN CONCAT(CAST(trusteeship_housedel_code AS STRING), CAST(housedel_id AS STRING))
                    ELSE NULL 
                END) AS unstart_house_cnt,  -- 未开始招租房源量
                COUNT(DISTINCT CASE 
                    WHEN if_first_seek_expire_unhouseout = 1
                    THEN CONCAT(CAST(trusteeship_housedel_code AS STRING), CAST(housedel_id AS STRING))
                    ELSE NULL 
                END) AS cur_seek_expire_unhouseout_cnt,  -- 当前首次招租已到期待出量
                COUNT(DISTINCT CASE 
                    WHEN if_0507erchu_seek_expire_unhouseout = 1
                    THEN CONCAT(CAST(trusteeship_housedel_code AS STRING), CAST(housedel_id AS STRING))
                    ELSE NULL 
                END) AS cur_0507erchu_seek_expire_unhouseout_cnt  -- 当前05/07二次招租已到期待出量
            FROM
                rpt.rpt_sxz_report_housein_detail_da
            WHERE
                pt BETWEEN '20250601000000' AND '20260131000000'
                AND (
                    -- 历史月最后一天
                    pt = CONCAT(DATE_FORMAT(LAST_DAY(CONCAT_WS('-', SUBSTR(pt, 1, 4), SUBSTR(pt, 5, 2), '01')), 'yyyyMMdd'), '000000')
                    OR
                    -- 昨天的pt
                    pt = '${-1d_pt}'
                )
            GROUP BY
                pt,
                city_name,
                COALESCE(bizcircle_name, '')  -- 按商圈分组
        ) t
),

-- 3. 生成月份×城市×商圈的组合（确保所有组合都有数据）
month_city_bizcircle AS (
    SELECT DISTINCT
        month_string,
        city_name,
        bizcircle_name
    FROM
        (
            -- 从咨询工单中获取
            SELECT
                month_string,
                city_name,
                bizcircle_name
            FROM
                consultation_tickets
            WHERE
                month_string >= '2025-06'
            
            UNION
            
            -- 从考核在管中获取
            SELECT
                month_string,
                city_name,
                bizcircle_name
            FROM
                manager_data
        ) t
)

insert overwrite table rpt.rpt_wanjia_weixiu_inquiry_volume partition (pt='${-1d_pt}')

SELECT
    mcb.month_string AS `月份`,
    mcb.city_name AS `城市`,
    mcb.bizcircle_name AS `商圈`,
    NVL(ct.consultation_count, 0) AS `咨询工单数`,  -- 分子
    NVL(md.house_kaohe_cnt, 0) AS `考核在管`  -- 分母
FROM
    month_city_bizcircle mcb
LEFT JOIN
    consultation_tickets ct
    ON mcb.month_string = ct.month_string
    AND mcb.city_name = ct.city_name
    AND mcb.bizcircle_name = ct.bizcircle_name
LEFT JOIN
    manager_data md
    ON mcb.month_string = md.month_string
    AND mcb.city_name = md.city_name
    AND mcb.bizcircle_name = md.bizcircle_name  -- 加上商圈匹配
WHERE
    mcb.month_string >= '2025-06'
ORDER BY
    mcb.city_name,
    mcb.bizcircle_name,
    mcb.month_string