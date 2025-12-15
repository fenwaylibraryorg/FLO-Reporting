--metadb:function lostInTransit

DROP FUNCTION IF EXISTS lostInTransit;

CREATE FUNCTION lostInTransit()
RETURNS TABLE
  (title text,
  item_barcode text,
  call_number text,
  shelving_location text,
  material_type text,
  status_name text,
  user_barcode text 
  )
AS $$
select 
  t.title,
  it.barcode as item_barcode, 
  hrt.call_number, 
  lt2.name as shelving_location,
  mtt.name as material_type,
  jsonb_extract_path_text(i.jsonb, 'status', 'name') AS status_name,
  ut.barcode as user_barcode
  from 
  folio_inventory.item__t it
  left join folio_inventory.item i on (it.id = i.id)
  left join folio_inventory.holdings_record__t hrt on (it.holdings_record_id = hrt.id)
  left join folio_inventory.instance__t t on (t.id = hrt.instance_id) 
  left join folio_circulation.loan__t lt on (lt.item_id = it.id) 
  left join folio_users.users__t ut on (ut.id = lt.user_id)
  left join folio_inventory.location__t lt2 ON (lt2.id = hrt.permanent_location_id)
  left join folio_inventory.material_type__t mtt ON (mtt.id = it.material_type_id)
  where 
  jsonb_extract_path_text(i.jsonb, 'status', 'name') in ('Missing', 'Aged to lost', 'Declared lost', 'In transit', 'Long missing')
  order by it.effective_shelving_order
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
