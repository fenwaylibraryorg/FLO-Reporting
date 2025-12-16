--metadb:function digitalHoldings

DROP FUNCTION IF EXISTS digitalHoldings;

CREATE FUNCTION digitalHoldings()
RETURNS TABLE
  (location_name text,
  holdings_count integer
  )
AS $$
select lt.name as location_name, count (distinct hrt.id) as holdings_count
from 
  folio_inventory.holdings_record__t hrt
  left join folio_inventory.instance__t it ON (hrt.instance_id = it.id)
  left join folio_inventory.location__t lt ON (hrt.effective_location_id = lt.id)
  where lt.name IN ('Ebooks','Ejournals','Streaming') 
  and ((it.discovery_suppress is FALSE and hrt.discovery_suppress is FALSE)
  or (it.discovery_suppress is FALSE and hrt.discovery_suppress is NULL))
  group by lt.name
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
