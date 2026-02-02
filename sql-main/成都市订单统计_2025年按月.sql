-- 成都市订单统计_2025年按月
-- 统计检修单量、租后单量、紧急单量、夜间单量（排除漏水）

SELECT 
  MONTH(a.order_create_time) AS `月份`,
  -- 检修单量：label_group IN ('1','25') 并且 lease_status IN (-1,1)
  COUNT(DISTINCT CASE 
    WHEN a.label_group IN ('1', '25') AND a.lease_status IN (-1, 1) 
    THEN a.service_order_code 
  END) AS `检修单量`,
  -- 租后单量：label_group NOT IN ('1','8','25') 并且 lease_status IN (2,3)
  COUNT(DISTINCT CASE 
    WHEN a.label_group NOT IN ('1', '8', '25') AND a.lease_status IN (2, 3) 
    THEN a.service_order_code 
  END) AS `租后单量`,
  -- 紧急单量：urgent_flag=1
  COUNT(DISTINCT CASE 
    WHEN a.urgent_flag = 1 
    THEN a.service_order_code 
  END) AS `紧急单量`,
  -- 夜间单量：首次签到时间在晚上11点-早上6点（23:00-06:00）
  COUNT(DISTINCT CASE 
    WHEN HOUR(a.first_sign_time) >= 23 OR HOUR(a.first_sign_time) < 6 
    THEN a.service_order_code 
  END) AS `夜间单量`,
  -- 总单量
  COUNT(DISTINCT a.service_order_code) AS `总单量`
FROM olap.olap_hj_fas_main_order_service_info_da a
INNER JOIN (
  -- 关联轻托管明细表，排除漏水
  SELECT 
    order_no AS oth_orderno
  FROM rpt.rpt_fas_light_hosting_order_detail_da
  WHERE pt = '20260114000000'
    AND vison_type = '4.0'
    AND service_name IN ('维修', '燃气')
    AND order_type = '16'
    -- 排除漏水
    AND commodity_name_list1 != '漏水专项检修'
    AND commodity_name_list1 NOT IN ('夏季空调预检', 'SCM00300001672373', '漏水专项检修', '消防器材', '定损', '漏水定损', '火灾定损', '其他定损', '京北漏水定损', '京南漏水定损', '京北火灾定损', '京南火灾定损', '京北其他定损', '京南其他定损')
    AND supplier_name NOT IN ('上海兰宫建筑装饰有限公司', '上海尚礼实业有限公司', '上海苏皖贸易有限公司', '上海再旭保洁服务有限公司', '源和里仁家具海安有限公司', '匠云（北京）科技有限公司')
) c ON a.order_no = c.oth_orderno
WHERE a.pt = '20260114000000'
  -- 筛选2025年数据（根据创建时间）
  AND YEAR(a.order_create_time) = 2025
  AND a.order_type = 16
  -- 筛选成都市
  AND a.city_name = '成都市'
GROUP BY 
  MONTH(a.order_create_time)
ORDER BY 
  `月份`
