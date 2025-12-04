--metadb:function itemsByLoc

DROP FUNCTION IF EXISTS itemsByLoc;

CREATE FUNCTION itemsByLoc()
RETURNS TABLE
  (location_code text,
  location_name text,
  item_count integer)
AS $$
select
	lt.code as location_code,
	lt.name as location_name,
	count(it2.id) as item_count
from
	folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on
	(hrt.instance_id = it.id)
left join folio_inventory.item__t it2 on
	(it2.holdings_record_id = hrt.id)
left join folio_inventory.location__t lt on
	(it2.effective_location_id = lt.id)
where
	lt.name is not null
group by
	lt.code,
	lt.name
order by
	lt.name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
