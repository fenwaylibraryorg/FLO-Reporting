--metadb:function microforms

DROP FUNCTION IF EXISTS microforms;

CREATE FUNCTION microforms()
RETURNS TABLE
  (title text,
  instance_hrid text,
  call_number text,
  effective_location_name text,
  barcode text,
  chronology text,
  volume text,
  material_type_name text,
  field300 text
  )
AS $$
select
	ie.title,
	ie.instance_hrid,
	he.call_number,
	ie2.effective_location_name,
	ie2.barcode,
	ie2.chronology,
	ie2.volume,
	ie2.material_type_name,
	mt.content as field300 
from
	folio_source_record.marc__t mt
left join folio_derived.instance_ext ie on
	(ie.instance_hrid = mt.instance_hrid)
left join folio_derived.holdings_ext he on
	(he.instance_id = ie.instance_id)
left join folio_derived.item_ext ie2 on
	(ie2.holdings_record_id = holdings_id)
left join folio_inventory.item__t it on
	(ie2.item_id = it.id)
where
	mt.field = '300'
	and mt.sf = 'a'
	and (((lower(mt.content) like '%microfilm%')
		or (lower(mt.content) like '%microform%')
			or (lower(mt.content) like '%microfiche%'))
		or 
  ((ie2.material_type_name = 'Microform')
			or (ie2.material_type_name = 'Microfilm')))
order by
	it.effective_shelving_order,
	ie2.volume
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
