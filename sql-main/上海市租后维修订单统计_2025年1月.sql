-- 上海市2025年1月租后维修订单统计（区分紧急单和非紧急单）
-- 参考健康度.sql的去除条件

WITH 
-- 异常签到识别（10分钟内3次以上签到）
sign_details AS (
  SELECT
    service_order_professional_ucid AS `服务者UCID`,
    first_sign_time AS `签到时间`,
    unix_timestamp(first_sign_time) AS ts,
    house_resource_id AS `房源ID`,
    order_no AS `服务单号`
  FROM (
    SELECT DISTINCT
      service_order_professional_ucid,
      first_sign_time,
      house_resource_id,
      order_no
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${-1d_pt}'
      AND order_type = 16
      AND label_group NOT IN ('8','1','25')
      AND lease_status IN (2,3)
      AND house_resource_id IS NOT NULL
      AND first_sign_time >= '2025-01-01'
      AND service_order_professional_ucid != -911
  ) s
),
win_pairs AS (
  SELECT
    a.`服务者UCID`,
    a.`服务单号` AS `锚点服务单号`,
    a.`签到时间` AS `窗口锚点时间`,
    a.ts AS anchor_ts,
    b.`服务单号` AS `窗口内服务单号`,
    b.`签到时间` AS `窗口内签到时间`,
    b.`房源ID` AS `窗口内房源ID`
  FROM sign_details a
  JOIN sign_details b
    ON a.`服务者UCID` = b.`服务者UCID`
  WHERE b.ts >= a.ts
    AND b.ts <= a.ts + 600  -- 10分钟窗口
),
window_stats AS (
  SELECT
    `服务者UCID`,
    `锚点服务单号`,
    `窗口锚点时间` AS `10分钟窗口起始时间`,
    anchor_ts,
    MIN(`窗口内签到时间`) AS `第一次签到时间`,
    COUNT(DISTINCT `窗口内服务单号`) AS `10分钟窗口签到次数`,
    COUNT(DISTINCT `窗口内房源ID`)  AS `不同房源数`
  FROM win_pairs
  GROUP BY `服务者UCID`, `锚点服务单号`, `窗口锚点时间`, anchor_ts
  HAVING COUNT(DISTINCT `窗口内服务单号`) >= 3
     AND COUNT(DISTINCT `窗口内房源ID`)  >= 3
),
-- 异常签到订单列表
excluded_orders_with_count AS (
  SELECT DISTINCT
    p.`窗口内服务单号` AS `服务单号`
  FROM win_pairs p
  JOIN window_stats v
    ON p.`服务者UCID` = v.`服务者UCID`
    AND p.`锚点服务单号` = v.`锚点服务单号`
)

-- 主查询
SELECT 
    '上海市' AS `城市`,
    '2025-01' AS `统计月份`,
    
    -- 紧急单统计
    COUNT(DISTINCT CASE 
        WHEN kk.`总订单` IS NOT NULL 
        THEN a.order_no 
    END) AS `紧急单订单数`,
    
    -- 非紧急单统计
    COUNT(DISTINCT CASE 
        WHEN kk.`总订单` IS NULL 
        THEN a.order_no 
    END) AS `非紧急单订单数`,
    
    -- 总订单数
    COUNT(DISTINCT a.order_no) AS `总订单数`,
    
    -- 紧急单明细
    COLLECT_SET(CASE 
        WHEN kk.`总订单` IS NOT NULL 
        THEN a.order_no 
    END) AS `紧急单订单列表`,
    
    -- 非紧急单明细
    COLLECT_SET(CASE 
        WHEN kk.`总订单` IS NULL 
        THEN a.order_no 
    END) AS `非紧急单订单列表`

FROM 
    -- 主订单表
    (SELECT DISTINCT 
        order_no,
        order_create_time,
        cancel_time,
        service_order_code,
        city_name,
        label_group,
        lease_status
    FROM olap.olap_hj_fas_main_order_service_info_da
    WHERE pt = '${-1d_pt}'
        AND order_type = 16
        AND city_name = '上海市'
        AND SUBSTR(order_create_time, 1, 7) = '2025-01'
        AND label_group NOT IN ('8')  -- 排除检修相关
    ) AS a

    -- 关联订单详情表（应用更多过滤条件）
    INNER JOIN (
        SELECT
            order_no AS oth_orderno,
            create_time,
            order_after_sign_diff_out,
            CASE 
                WHEN service_time_end > original_service_time_end 
                THEN service_time_end 
                ELSE original_service_time_end 
            END AS final_time
        FROM rpt.rpt_fas_light_hosting_order_detail_da
        WHERE pt = '${-1d_pt}'
            AND vison_type = '4.0'
            AND service_name IN ('维修','燃气')
            AND order_type = '16'
            AND label_group NOT IN ('8')  -- 排除检修
            -- 排除特定商品
            AND commodity_name_list1 NOT IN (
                '夏季空调预检','SCM00300001672373','漏水专项检修','消防器材',
                '定损','漏水定损','火灾定损','其他定损',
                '京北漏水定损','京南漏水定损','京北火灾定损','京南火灾定损',
                '京北其他定损','京南其他定损'
            )
            -- 排除特定供应商
            AND supplier_name NOT IN (
                '上海兰宫建筑装饰有限公司','上海尚礼实业有限公司',
                '上海苏皖贸易有限公司','上海再旭保洁服务有限公司',
                '源和里仁家具海安有限公司','匠云（北京）科技有限公司'
            )
    ) b ON b.oth_orderno = a.order_no
    
    -- 关联紧急单信息
    LEFT JOIN (
        SELECT DISTINCT 
            order_no AS order_no_1,
            order_create_time,
            CASE 
                WHEN is_urgent_order = 1 OR is_urgent_switch = 1 
                THEN order_no  
            END AS `总订单`,
            CASE 
                WHEN is_2_hour_urgent_on_door = 1 
                    AND (is_urgent_order = 1 OR is_urgent_switch = 1) 
                THEN order_no 
            END AS `2h上门`,
            CASE 
                WHEN is_30_min_urgent_call = 1 
                    AND (is_urgent_order = 1 OR is_urgent_switch = 1) 
                THEN order_no 
            END AS `紧急30分钟致电单`
        FROM rpt.rpt_jiafu_urgent_order_info_da
        WHERE pt = '${-1d_pt}'
            AND city_name = '上海市'
            AND SUBSTR(order_create_time, 1, 7) = '2025-01'
            AND (urgent_flag IN (1, 2) OR performance_mode IN (1, 2))
    ) kk ON kk.order_no_1 = a.order_no
    
    -- 关联异常签到信息
    LEFT JOIN (
        SELECT
            main.order_no AS order_no_2,
            MAX(IF(feedback.feedback_type = 1 OR ext_info.sign_exception = 1, main.order_no, NULL)) AS e_order,
            MAX(eowc.`服务单号`) AS `10分钟窗口签到次数`
        FROM olap.olap_hj_fas_main_order_service_info_da main
        LEFT JOIN excluded_orders_with_count eowc
            ON main.order_no = eowc.`服务单号`
        LEFT JOIN (
            SELECT service_order_code, MAX(feedback_type) AS feedback_type 
            FROM ods.ods_plat_jiafu_dispatch_service_order_sign_in_feedback_di 
            WHERE pt = '${-1d_pt}' 
            GROUP BY service_order_code
        ) feedback ON main.service_order_code = feedback.service_order_code
        LEFT JOIN (
            SELECT service_order_code, MAX(sign_exception) AS sign_exception 
            FROM ods.ods_plat_jiafu_dispatch_service_order_ext_info_da 
            WHERE pt = '${-1d_pt}' 
            GROUP BY service_order_code
        ) ext_info ON main.service_order_code = ext_info.service_order_code
        WHERE main.pt = '${-1d_pt}'
            AND main.order_type = 16 
            AND main.label_group NOT IN ('8', '1', '25') 
            AND main.lease_status IN (2, 3) 
            AND main.house_resource_id IS NOT NULL 
            AND main.order_no IS NOT NULL 
        GROUP BY main.order_no
    ) tt1 ON tt1.order_no_2 = a.order_no

WHERE 
    -- 只统计租后维修（label_group NOT IN ('1', '25') 表示非检修和非其他类型）
    a.label_group NOT IN ('1', '8', '25')
    -- 租赁状态为2或3（租后）
    AND a.lease_status IN (2, 3)
    -- 排除1小时内取消的订单
    AND (
        a.cancel_time = '1000-01-01 00:00:00' 
        OR (UNIX_TIMESTAMP(a.cancel_time, 'yyyy-MM-dd HH:mm:ss') - UNIX_TIMESTAMP(a.order_create_time, 'yyyy-MM-dd HH:mm:ss')) / 60 > 60
    )
    -- 排除异常签到订单
    AND tt1.`10分钟窗口签到次数` IS NULL
;
