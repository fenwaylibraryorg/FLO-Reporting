--metadb:function springerCallNo

DROP FUNCTION IF EXISTS springerCallNo;

CREATE FUNCTION springerCallNo()
RETURNS TABLE
  (instance_hrid text,
  title text,
  holdings_hrid text,
  call_number text,
  uri text
  )
AS $$
select
	distinct it.hrid as instance_hrid,
	it.title,
	hrt.hrid as holdings_hrid,
	hrt.call_number,
	jsonb_extract_path_text(electronic_access.jsonb,
	'uri') as uri
from
	folio_inventory.instance__t it
inner join folio_inventory.holdings_record__t hrt on
	it.id = hrt.instance_id
inner join folio_inventory.holdings_record hr on
	hrt.id = hr.id
cross join lateral jsonb_array_elements(jsonb_extract_path(hr.jsonb,
	'electronicAccess')) as electronic_access(jsonb)
where
	hrt.call_number like 'Springer%'
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
