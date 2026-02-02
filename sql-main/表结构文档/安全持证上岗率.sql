--模板查询：安全持证上岗率
--模板查询：安全资质持证上岗率
select t1.city_name,
t1.service_order_supplier_name,
count(distinct case when t1.`维修家电` = 1 then t1.staff_ucid else null end) as `家电有完工人数`,
count(distinct case when t1.`维修综合` = 1 then t1.staff_ucid else null end) as `综合有完工人数`,
count(distinct case when t1.`维修家电` = 1 and t2.`资质类型` = '高空作业证' then t1.staff_ucid else null end) as `家电有资质人数`,
count(distinct case when t1.`维修综合` = 1 and t2.`资质类型` = '低压电工证' then t1.staff_ucid else null end) as `综合有资质人数`
from(select distinct a.*,b.city_name,b.service_order_supplier_name
	 from 
  (select staff_ucid,
  name,
  CASE when ability_list like '%燃气%' then 1 else 0 end as `燃气`,
           CASE  WHEN ability_list LIKE '%维修综合%' THEN 1 else 0 end as `维修综合`,
   CASE  WHEN ability_list LIKE '%维修家电%' THEN 1 else 0 end as `维修家电`
  from olap.olap_fas_mht_staff_detail_da
where pt = '20260115000000'
  and status_code = 0
  and is_delete = 0
  and biz_line = 10003
  and role_list = '维修员') a
join 
  (select service_order_professional_ucid,
   city_name,
   service_order_supplier_name,
   count (distinct service_order_code) as num
   from olap.olap_hj_fas_main_order_service_info_da
   where pt = '20260115000000'
   and service_code = '10003'
        AND order_type = 16
        AND label_group NOT IN ('8')
        AND service_order_complete_time BETWEEN '2025-12-16' AND '2026-01-15'
  group by 1,2,3) b
  on a.staff_ucid = b.service_order_professional_ucid
-- where b.num >= 30
) t1
left join 
(
    -- 核心修改：先筛选出每个服务者+资质类型下更新时间最新的记录
    SELECT 
        professional_ucid,
        supplier_name,
        certificate_type,
        -- 提前转换资质类型，避免GROUP BY重复写CASE WHEN
        CASE 
            WHEN certificate_type = '1' THEN '低压电工证'
            WHEN certificate_type = '2' THEN '高空作业证'
            WHEN certificate_type = '3' THEN '燃气具安装维修工'
            WHEN certificate_type = '4' THEN '贝壳认证培训证书'
            ELSE '其他资质'
        END AS `资质类型`
    FROM (
        SELECT 
            professional_ucid,
            supplier_name,
            certificate_type,
            -- 按服务者+资质类型分组，更新时间降序排序，取最新
            ROW_NUMBER() OVER (
                PARTITION BY professional_ucid, certificate_type 
                ORDER BY update_time DESC
            ) AS rn_a
        FROM ods.ods_plat_busercenter_professional_qualification_approval_di
        WHERE pt BETWEEN '20251001000000' AND '20260115000000'
	  and is_delete = 0 and approval_status = 2
    ) t
    WHERE t.rn_a = 1 -- 筛选更新时间最新的记录
) t2
on t1.staff_ucid = t2.professional_ucid
group by 1,2