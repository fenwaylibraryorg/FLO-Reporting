--metadb:function itemsByStatusMatType

DROP FUNCTION IF EXISTS itemsByStatusMatType;

CREATE FUNCTION itemsByStatusMatType()
RETURNS TABLE
  (status_name text,
  material_type_name text,
  item_count integer)
AS $$
select
	ie.status_name,
	ie.material_type_name,
	count(ie.item_id) as item_count
from
	folio_derived.item_ext ie
group by
	ie.status_name,
	ie.material_type_name
order by
	ie.status_name,
	ie.material_type_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
