--metadb:function eresourcesByDate

DROP FUNCTION IF EXISTS eresourcesByDate;

CREATE FUNCTION eresourcesByDate(
    start_date text DEFAULT '',
    end_date text DEFAULT '')
RETURNS TABLE(
  eresource_count integer
  )
AS $$
select
	count(mt.instance_id) as eresource_count
from
	folio_source_record.marc__t mt
left join folio_derived.instance_ext ie on
	(mt.instance_id = ie.instance_id)
left join folio_derived.instance_formats isf on
	(isf.instance_id = ie.instance_id)
where
	mt.field = '008'
	and isf.instance_format_name = 'computer -- online resource'
	and left(mt.content,
	6) between start_date and end_date
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
