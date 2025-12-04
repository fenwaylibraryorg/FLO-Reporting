--metadb:function itemsByStatus

DROP FUNCTION IF EXISTS itemsByStatus;

CREATE FUNCTION itemsByStatus()
RETURNS TABLE
  (status_name text,
  item_count integer)
AS $$
select
	ie.status_name,
	count(ie.item_id) as item_count
from
	folio_derived.item_ext ie
group by
	ie.status_name
order by
	ie.status_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
