--metadb:function ckoutsRenewalsiType

DROP FUNCTION IF EXISTS ckoutsRenewalsiType;

CREATE FUNCTION ckoutsRenewalsiType(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (material_type text,
  count integer)
AS $$
select coalesce(mtt.name, 'Total') as material_type, count(lt.action) from folio_circulation.loan__t__ lt
  left join folio_inventory.item__t it ON (it.id = lt.item_id)
  left join folio_inventory.material_type__t mtt ON (mtt.id = it.material_type_id)
  left join folio_inventory.location__t lt2 ON (it.effective_location_id = lt2.id)
  left join folio_inventory.loclibrary__t lt3 ON (lt3.id = lt2.library_id) 
where lt.loan_date between start_date and end_date 
and lt.action in ('checkedout','renewed','checkedOutThroughOverride')
and lt3.name in ('Albert Alphin Library', 'Stan Getz Library', 'Valencia Library') 
group by ROLLUP (mtt.name)
order by mtt.name nulls last
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
