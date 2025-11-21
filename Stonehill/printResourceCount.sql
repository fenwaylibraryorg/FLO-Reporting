--metadb:function printResourceCount

DROP FUNCTION IF EXISTS printResourceCount;

CREATE FUNCTION printResourceCount()
RETURNS TABLE
  (instance_count integer,
  material_type_name text)
AS $$
select
    count(distinct it.id) as instance_count,
    it2.material_type_name
from
    folio_inventory.instance__t it
    join folio_derived.holdings_ext ih on (ih.instance_id = it.id)
    join folio_derived.item_ext it2 on (it2.holdings_record_id = ih.holdings_id)
where it2.material_type_name not in ('Music CD', 'Archival Materials', 'DVD', 'Microform', 'Library of Things')
  group by
    it2.material_type_name
order by count(it2.item_id) desc
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
