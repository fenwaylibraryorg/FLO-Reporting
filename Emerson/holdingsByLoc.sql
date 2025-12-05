--metadb:function holdingsByLoc

DROP FUNCTION IF EXISTS holdingsByLoc;

CREATE FUNCTION holdingsByLoc()
RETURNS TABLE
  (location_name text,
  location_code text,
  Holdings_count integer)
AS $$
select
	lt.name as Location_name,
	lt.code as location_code,
	count (hrt.id) as Holdings_count
from
	folio_inventory.holdings_record__t hrt
left join folio_inventory.location__t lt on
	(hrt.permanent_location_id = lt.id)
group by
	lt.name,
	lt.code
order by
	lt.name,
	lt.code
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
