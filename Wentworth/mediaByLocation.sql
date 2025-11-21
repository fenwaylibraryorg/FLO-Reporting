--metadb:function mediaByLocation

DROP FUNCTION IF EXISTS mediaByLocation;

CREATE FUNCTION mediaByLocation()
RETURNS TABLE
  (location text,
  item_type text,
  items_count integer)
AS $$
SELECT lt.name as Location, mtt.name as item_type, COUNT (it.id) as items_count
FROM folio_inventory.item__t it
LEFT JOIN folio_inventory.location__t lt ON (lt.id = it.effective_location_id)
LEFT JOIN folio_inventory.material_type__t mtt ON (mtt.id = it.material_type_id)
WHERE mtt.name NOT LIKE 'Book'
GROUP BY lt.name, mtt.name
ORDER BY lt.name, mtt.name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
