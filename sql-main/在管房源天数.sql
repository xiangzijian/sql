WITH subquery AS (
SELECT 
        trusteeship_housedel_code,
        manager_corp_name,  
        TO_DATE(MIN(sign_date)) AS `开始日1`,
        IF(
            SUM(CASE WHEN terminate_time IS NOT NULL AND terminate_time != '' THEN 1 ELSE 0 END) > 0,
            TO_DATE(MIN(terminate_time)),
            TO_DATE(MIN(last_effect_end_date))
        ) AS `结束日1`,
        CONCAT(
            CASE WHEN month_seq <= 12 THEN '2025-' ELSE '2026-' END,
            LPAD(CASE WHEN month_seq <= 12 THEN month_seq ELSE month_seq - 12 END, 2, '0'),
            '-01'
        ) AS `month_start`,
        LAST_DAY(TO_DATE(CONCAT(
            CASE WHEN month_seq <= 12 THEN '2025-' ELSE '2026-' END,
            LPAD(CASE WHEN month_seq <= 12 THEN month_seq ELSE month_seq - 12 END, 2, '0'),
            '-01'
        ))) AS `month_end`,
        GREATEST(
            TO_DATE(CONCAT(
                CASE WHEN month_seq <= 12 THEN '2025-' ELSE '2026-' END,
                LPAD(CASE WHEN month_seq <= 12 THEN month_seq ELSE month_seq - 12 END, 2, '0'),
                '-01'
            )), 
            TO_DATE(MIN(sign_date))
        ) AS `开始日2`,
        LEAST(
            LAST_DAY(TO_DATE(CONCAT(
                CASE WHEN month_seq <= 12 THEN '2025-' ELSE '2026-' END,
                LPAD(CASE WHEN month_seq <= 12 THEN month_seq ELSE month_seq - 12 END, 2, '0'),
                '-01'
            ))), 
            IF(
                SUM(CASE WHEN terminate_time IS NOT NULL AND terminate_time != '' THEN 1 ELSE 0 END) > 0,
                TO_DATE(MIN(terminate_time)),
                TO_DATE(MIN(last_effect_end_date))
            )
        ) AS `结束日2`,
        CASE 
            WHEN LEAST(
                LAST_DAY(TO_DATE(CONCAT(
                    CASE WHEN month_seq <= 12 THEN '2025-' ELSE '2026-' END,
                    LPAD(CASE WHEN month_seq <= 12 THEN month_seq ELSE month_seq - 12 END, 2, '0'),
                    '-01'
                ))), 
                IF(
                    SUM(CASE WHEN terminate_time IS NOT NULL AND terminate_time != '' THEN 1 ELSE 0 END) > 0,
                    TO_DATE(MIN(terminate_time)),
                    TO_DATE(MIN(last_effect_end_date))
                )
            ) < GREATEST(
                TO_DATE(CONCAT(
                    CASE WHEN month_seq <= 12 THEN '2025-' ELSE '2026-' END,
                    LPAD(CASE WHEN month_seq <= 12 THEN month_seq ELSE month_seq - 12 END, 2, '0'),
                    '-01'
                )), 
                TO_DATE(MIN(sign_date))
            ) THEN 0
            ELSE DATEDIFF(
                LEAST(
                    LAST_DAY(TO_DATE(CONCAT(
                        CASE WHEN month_seq <= 12 THEN '2025-' ELSE '2026-' END,
                        LPAD(CASE WHEN month_seq <= 12 THEN month_seq ELSE month_seq - 12 END, 2, '0'),
                        '-01'
                    ))), 
                    IF(
                        SUM(CASE WHEN terminate_time IS NOT NULL AND terminate_time != '' THEN 1 ELSE 0 END) > 0,
                        TO_DATE(MIN(terminate_time)),
                        TO_DATE(MIN(last_effect_end_date))
                    )
                ),
                GREATEST(
                    TO_DATE(CONCAT(
                        CASE WHEN month_seq <= 12 THEN '2025-' ELSE '2026-' END,
                        LPAD(CASE WHEN month_seq <= 12 THEN month_seq ELSE month_seq - 12 END, 2, '0'),
                        '-01'
                    )), 
                    TO_DATE(MIN(sign_date))
                )
            ) + 1
        END AS `单个房源每月在管天数`
    FROM 
        olap.olap_trusteeship_hdel_housein_da
    JOIN (
        SELECT 1 AS month_seq UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
        UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13
    ) months ON 1 = 1
    WHERE 
        pt = '20260119000000'
        AND manager_corp_name like '惠居%'
        AND contract_status_code IN (2, 3, 4, 5)
    GROUP BY 
        trusteeship_housedel_code,
        manager_corp_name, 
        month_seq
)
SELECT 
    manager_corp_name,  
    `month_start` AS `月份`,
    SUM(`单个房源每月在管天数`) AS `总在管天数`
FROM 
    subquery
GROUP BY 
    manager_corp_name, 
    `month_start`
ORDER BY 
    manager_corp_name,  
    `month_start`