--metadb:function ipedsPhysical

DROP FUNCTION IF EXISTS ipedsPhysical;

CREATE FUNCTION ipedsPhysical()
RETURNS TABLE
  (material_type text,
  holdings_count integer
  )
AS $$
select mtt.name as material_type, count (distinct hrt.id) as holdings_count
from 
  folio_inventory.holdings_record__t hrt
  left join folio_inventory.instance__t it ON (hrt.instance_id = it.id)
  left join folio_inventory.item__t it2 ON (hrt.id = it2.holdings_record_id)
  left join folio_inventory.material_type__t mtt ON (it2.material_type_id = mtt.id)
  where mtt.name NOT IN ('Online','Tests','Comcat Item','ReShare Item')
 and ((it.discovery_suppress is FALSE and hrt.discovery_suppress is FALSE) or (it.discovery_suppress is fALSE and hrt.discovery_suppress is NULL))
  group by mtt.name
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
