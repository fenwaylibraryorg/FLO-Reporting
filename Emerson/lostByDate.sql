--metadb:function lostByDate

DROP FUNCTION IF EXISTS lostByDate;

CREATE FUNCTION lostByDate(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (title text,
  barcode text,
  call_number text,
  shelving_location text,
  material_type text,
  status_name text,
  status_date text)
AS $$
select 
  t.title,
  it.barcode, 
  hrt.call_number,
  lt2.name as shelving_location,
  mtt.name as material_type,
  jsonb_extract_path_text(i.jsonb, 'status', 'name') AS status_name,
  jsonb_extract_path_text(i.jsonb, 'status', 'date')::date::text AS status_date
  from 
  folio_inventory.item__t it
  left join folio_inventory.item i on (it.id = i.id)
  left join folio_inventory.holdings_record__t hrt on (it.holdings_record_id = hrt.id)
  left join folio_inventory.instance__t t on (t.id = hrt.instance_id) 
  left join folio_circulation.loan__t lt on (lt.item_id = it.id) 
  left join folio_inventory.location__t lt2 ON (lt2.id = hrt.permanent_location_id)
  left join folio_inventory.material_type__t mtt ON (mtt.id = it.material_type_id)
  where 
  jsonb_extract_path_text(i.jsonb, 'status', 'name') in ('Missing', 'Aged to lost', 'Declared lost', 'Restricted')
  and
  jsonb_extract_path_text(i.jsonb, 'status', 'date') between start_date and end_date 
  order by it.effective_shelving_order
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
