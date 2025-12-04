--metadb:function itemsByMatType

DROP FUNCTION IF EXISTS itemsByMatType;

CREATE FUNCTION itemsByMatType()
RETURNS TABLE
  (library_name text,
  material_type_name text,
  item_count integer)
AS $$
select
	ll.library_name as library_name,
	ie.material_type_name,
	count(ie.item_id) as item_count
from
	folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on
	(hrt.instance_id = it.id)
left join folio_derived.item_ext ie on
	(ie.holdings_record_id = hrt.id)
left join folio_derived.locations_libraries ll on
	(ie.effective_location_id = ll.location_id)
where
	ll.library_name is not null
group by
	ll.library_name,
	ie.material_type_name
order by
	ll.library_name,
	ie.material_type_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
