-- 商品完工时长统计（区分检修和租期维修）_2025年
-- 只按照商品统计平均完工时长数据

SELECT 
  b.commodity_name AS `商品名称`,
  CASE 
    WHEN a.label_group IN ('1', '25') AND a.lease_status IN (-1, 1) THEN '检修'
    WHEN a.label_group NOT IN ('1', '8', '25') AND a.lease_status IN (2, 3) THEN '租期维修'
    ELSE '其他'
  END AS `维修类型`,
  COUNT(DISTINCT a.service_order_code) AS `服务单数量`,
  -- 计算平均完工时长（单位：小时，保留2位小数）
  ROUND(AVG(
    UNIX_TIMESTAMP(a.service_order_complete_time) - UNIX_TIMESTAMP(a.first_sign_time)
  ) / 3600, 2) AS `平均完工时长_小时`,
  -- 计算平均完工时长（单位：天，保留2位小数）
  ROUND(AVG(
    UNIX_TIMESTAMP(a.service_order_complete_time) - UNIX_TIMESTAMP(a.first_sign_time)
  ) / 86400, 2) AS `平均完工时长_天`,
  -- 最短完工时长（小时）
  ROUND(MIN(
    UNIX_TIMESTAMP(a.service_order_complete_time) - UNIX_TIMESTAMP(a.first_sign_time)
  ) / 3600, 2) AS `最短完工时长_小时`,
  -- 最长完工时长（小时）
  ROUND(MAX(
    UNIX_TIMESTAMP(a.service_order_complete_time) - UNIX_TIMESTAMP(a.first_sign_time)
  ) / 3600, 2) AS `最长完工时长_小时`
FROM olap.olap_hj_fas_main_order_service_info_da a
INNER JOIN olap.olap_hj_fas_main_order_commodity_da b
  ON a.service_order_code = b.service_order_code
  AND a.pt = b.pt
INNER JOIN (
  -- 关联轻托管明细表，筛选维修相关订单
  SELECT 
    order_no AS oth_orderno
  FROM rpt.rpt_fas_light_hosting_order_detail_da
  WHERE pt = '20260114000000'
    AND vison_type = '4.0'
    AND service_name IN ('维修', '燃气')
    AND order_type = '16'
    -- 不排除检修，保留所有label_group
    AND commodity_name_list1 != '漏水专项检修'  -- 排除漏水
    AND commodity_name_list1 NOT IN ('夏季空调预检', 'SCM00300001672373', '漏水专项检修', '消防器材', '定损', '漏水定损', '火灾定损', '其他定损', '京北漏水定损', '京南漏水定损', '京北火灾定损', '京南火灾定损', '京北其他定损', '京南其他定损')  -- 排除定损
    AND supplier_name NOT IN ('上海兰宫建筑装饰有限公司', '上海尚礼实业有限公司', '上海苏皖贸易有限公司', '上海再旭保洁服务有限公司', '源和里仁家具海安有限公司', '匠云（北京）科技有限公司')
) c ON a.order_no = c.oth_orderno
WHERE a.pt = '20260114000000'
  -- 筛选2025年数据（根据完工时间）
  AND YEAR(a.service_order_complete_time) = 2025
  AND a.order_type = 16
  -- 筛选检修或租期维修数据
  AND (
    -- 检修：label_group IN ('1','25') 并且 lease_status IN (-1,1)
    (a.label_group IN ('1', '25') AND a.lease_status IN (-1, 1))
    OR
    -- 租期维修：label_group NOT IN ('1','8','25') 并且 lease_status IN (2,3)
    (a.label_group NOT IN ('1', '8', '25') AND a.lease_status IN (2, 3))
  )
  -- 确保签到时间和完工时间都存在
  AND a.first_sign_time IS NOT NULL
  AND a.service_order_complete_time IS NOT NULL
  -- 确保完工时间大于签到时间（排除异常数据）
  AND a.service_order_complete_time > a.first_sign_time
  -- 确保商品名称不为空
  AND b.commodity_name IS NOT NULL
GROUP BY 
  b.commodity_name,
  CASE 
    WHEN a.label_group IN ('1', '25') AND a.lease_status IN (-1, 1) THEN '检修'
    WHEN a.label_group NOT IN ('1', '8', '25') AND a.lease_status IN (2, 3) THEN '租期维修'
    ELSE '其他'
  END
ORDER BY 
  b.commodity_name,
  `维修类型`,
  `平均完工时长_小时` DESC
