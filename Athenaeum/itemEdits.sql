--metadb:function itemEdits

DROP FUNCTION IF EXISTS itemEdits;

CREATE FUNCTION itemEdits(
  update_user text DEFAULT '%',
  start_update_date date DEFAULT '2000-01-01',
  end_update_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  update_date_item text,
  update_staff_item text,
  instance_hrid text,
  title text,
  holdings_hrid text,
  call_number_prefix text,
  call_number text,
  item_hrid text,
  barcode text,
  copy_number text,
  volume text,
  enumeration text,
  chronology text,
  discovery_suppress boolean, 
  perm_item_location text,
  temp_item_location text,
  statistical_code text,
  statistical_code_name text, 
  item_status text,
  create_date_item text,
  create_staff_item text 
  )
AS $$
with 
  items_statistical_codes as (
select
	item.id as item_id,
	i.hrid as item_hrid,
	statistical_code_ids.data #>> '{}' as statistical_code_id
from
	folio_inventory.item
cross join lateral jsonb_array_elements(jsonb_extract_path(jsonb,
	'statisticalCodeIds')) as statistical_code_ids(data)
left join folio_inventory.item__t as i on
	item.id = i.id)
select
	jsonb_extract_path_text(i2.jsonb,
	'metadata',
	'updatedDate')::date::text as update_date_item,
	uuit.username as update_staff_item,
	it.hrid as instance_hrid,
	it.title,
	hrt.hrid as holdings_hrid,
	hrt.call_number_prefix,
	hrt.call_number,
	it2.hrid as item_hrid,
	it2.barcode,
	it2.copy_number,
	it2.volume,
	it2.enumeration,
	it2.chronology,
	it2.discovery_suppress,
	ltpi.name as perm_item_location,
	ltti.name as temp_item_location,
	sct2.code as statistical_code,
	sct2.name as statistical_code_name,
	jsonb_extract_path_text(i2.jsonb,
	'status',
	'name') as item_status,
	jsonb_extract_path_text(i2.jsonb,
	'metadata',
	'createdDate')::date::text as create_date_item,
	cuit.username as create_staff_item
from
	folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on
	(hrt.instance_id = it.id)
left join folio_inventory.item__t it2 on
	(hrt.id = it2.holdings_record_id)
left join folio_inventory.item i2 on
	(i2.id = it2.id)
left join folio_inventory.location__t ltpi on
	(it2.permanent_location_id = ltpi.id)
left join folio_inventory.location__t ltti on
	(it2.temporary_location_id = ltti.id)
left join items_statistical_codes on
	(items_statistical_codes.item_id = it2.id)
left join folio_inventory.statistical_code__t as sct2 on
	items_statistical_codes.statistical_code_id::uuid = sct2.id
left join folio_inventory.statistical_code_type__t as sctt2 on
	sct2.statistical_code_type_id::uuid = sctt2.id::uuid
left join folio_derived.users_groups cuit on
	(jsonb_extract_path_text(i2.jsonb,
	'metadata',
	'createdByUserId')::uuid = cuit.user_id)
left join folio_derived.users_groups uuit on
	(jsonb_extract_path_text(i2.jsonb,
	'metadata',
	'updatedByUserId')::uuid = uuit.user_id)
where
	((jsonb_extract_path_text(i2.jsonb,
	'metadata',
	'createdDate')::date between start_update_date and end_update_date)
		or 
  (jsonb_extract_path_text(i2.jsonb,
		'metadata',
		'updatedDate')::date between start_update_date and end_update_date))
	and (uuit.username not in ('circstaff', 'membership', 'poremski', 'ha', 'morini', 'omeara', 'system-ncip', 'flo-api', 'owilson@bostonathenaeum.org', 'id_admin', 'lobrutto', 'warnement', 'id_vufind_systemuser'))
    and (uuit.username like update_user) 
order by
	jsonb_extract_path_text(i2.jsonb,
	'metadata',
	'updatedDate')::date,
	uuit.username,
	it.hrid,
	hrt.hrid,
	it2.hrid
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
