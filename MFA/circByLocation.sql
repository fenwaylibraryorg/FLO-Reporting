--metadb:function circByLocation

DROP FUNCTION IF EXISTS circByLocation;

CREATE FUNCTION circByLocation(  
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  shelving_location text,
  circ_count integer
  )
AS $$
select
	coalesce(lt2.name, 'Total Circs') as shelving_location,
	count(lt.action) as circ_count
from
	folio_circulation.loan__t__ lt
left join folio_inventory.item__t it on
	(it.id = lt.item_id)
left join folio_inventory.location__t lt2 on
	(lt2.id = it.effective_location_id)
where
	lt.loan_date between start_date and end_date
	and lt.action in ('checkedout', 'renewed', 'renewedThroughOverride', 'checkedOutThroughOverride', 'dueDateChanged')
	and lt2.name is not null
group by
	rollup (lt2.name)
order by
	lt2.name nulls last
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
