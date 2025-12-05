--metadb:function inHouseAll

DROP FUNCTION IF EXISTS inHouseAll;

CREATE FUNCTION inHouseAll(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (material_type text,
  count integer)
AS $$
select
	mtt.name as material_type,
	count(distinct cit.id)
from
	folio_circulation.check_in__t__ cit
left join folio_inventory.item__t it on
	(it.id = cit.item_id)
left join folio_inventory.material_type__t mtt on
	(mtt.id = it.material_type_id)
left join folio_inventory.location__t lt2 on
	(it.effective_location_id = lt2.id)
left join folio_inventory.loclibrary__t lt3 on
	(lt3.id = lt2.library_id)
where
	cit.occurred_date_time between start_date and end_date
	and lt3.name in ('Albert Alphin Library', 'Stan Getz Library', 'Valencia Library')
	and cit.item_status_prior_to_check_in = 'Available'
group by
	mtt.name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
