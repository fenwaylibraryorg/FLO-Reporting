--metadb:function holdingsByLibrary

DROP FUNCTION IF EXISTS holdingsByLibrary;

CREATE FUNCTION holdingsByLibrary()
RETURNS TABLE
  (library_name text,
holdings_count integer)
AS $$
select
	ll.library_name as library_name,
	count(hrt.id) as holdings_count
from
	folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on
	(hrt.instance_id = it.id)
left join folio_derived.locations_libraries ll on
	(hrt.permanent_location_id = ll.location_id)
where
	ll.library_name is not null
group by
	ll.library_name
order by
	ll.library_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
