--metadb:function holdingsByiType

DROP FUNCTION IF EXISTS holdingsByiType;

CREATE FUNCTION holdingsByiType()
RETURNS TABLE
  (location text,
  Item_Type text,
  Holdings_count integer)
AS $$
select
	lt.name as location,
	mtt.name as Item_Type,
	COUNT (hrt.id) as Holdings_count
from
	folio_inventory.holdings_record__t hrt
inner join folio_inventory.location__t lt on
	(hrt.permanent_location_id = lt.id)
inner join folio_inventory.item__t it on
	(hrt.id = it.holdings_record_id)
inner join folio_inventory.material_type__t mtt on
	(mtt.id = it.material_type_id)
group by
	lt.name,
	mtt.name
order by
	lt.name,
	mtt.name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
