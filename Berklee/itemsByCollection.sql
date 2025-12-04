--metadb:function itemsByCollection

DROP FUNCTION IF EXISTS itemsByCollection;

CREATE FUNCTION itemsByCollection()
RETURNS TABLE
  (collection_code text,
  item_count integer)
AS $$
select in2.note as collection_code,
count(distinct in2.item_id) as item_count
from
folio_derived.item_notes in2
where
in2.note_type_name like 'Collection Code'
group by
in2.note
order by
in2.note
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
