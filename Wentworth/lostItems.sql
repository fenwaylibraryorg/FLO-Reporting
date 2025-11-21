--metadb:function lostItems

DROP FUNCTION IF EXISTS lostItems;

CREATE FUNCTION lostItems()
RETURNS TABLE
  (title text,
  status_name text, 
  status_date text,
  effective_shelving_order text,
  effective_location_name text,
  barcode text,
  enumeration_data text
 )
AS $$
select it.title, ie.status_name, ie.status_date, it2.effective_shelving_order, ie.effective_location_name, ie.barcode, coalesce(ie.enumeration, ie.chronology, ie.volume) as enumeration_data
from
folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on (it.id = hrt.instance_id) 
inner join folio_derived.item_ext ie on (ie.holdings_record_id = hrt.id)
inner join folio_inventory.item__t it2 on (ie.item_id = it2.id)
where ie.status_name like '%lost%'
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
