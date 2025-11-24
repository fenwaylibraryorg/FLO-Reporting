--metadb:function itemsByLocTypeDate

DROP FUNCTION IF EXISTS itemsByLocTypeDate;

CREATE FUNCTION itemsByLocTypeDate(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
 location_name text,
  material_type_name text,
  item_count integer
  )
AS $$
select ll.location_name, ie.material_type_name, count(ie.item_id) as item_count
from folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on (hrt.instance_id = it.id) 
left join folio_derived.item_ext ie on (ie.holdings_record_id = hrt.id) 
left join folio_derived.locations_libraries ll on (ie.effective_location_id = ll.location_id)
where ll.location_name is not null and ie.created_date between start_date and end_date
group by ll.location_name, ie.material_type_name
order by ll.location_name, ie.material_type_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
