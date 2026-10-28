--metadb:function instanceEdits

DROP FUNCTION IF EXISTS instanceEdits;

CREATE FUNCTION instanceEdits(
  update_user text DEFAULT '%',
  start_update_date date DEFAULT '2000-01-01',
  end_update_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  update_date_instance text,
  update_staff_instance text,
  hrid text,
  deleted boolean,
  staff_suppress boolean,
  title text,
  cataloged_date text,
  discovery_suppress boolean,
  create_date_instance text,
  create_staff_instance text 
  )
AS $$
select
	jsonb_extract_path_text(i.jsonb,
	'metadata',
	'updatedDate')::date::text as update_date_instance,
	uuin.username as update_staff_instance,
	it.hrid,
	it.deleted,
	it.staff_suppress,
	it.title,
	it.cataloged_date,
	it.discovery_suppress,
	jsonb_extract_path_text(i.jsonb,
	'metadata',
	'createdDate')::date::text as create_date_instance,
	cuin.username as create_staff_instance
from
	folio_inventory.instance__t it
left join folio_inventory.instance i on
	(i.id = it.id)
left join folio_derived.users_groups cuin on
	(jsonb_extract_path_text(i.jsonb,
	'metadata',
	'createdByUserId')::uuid = cuin.user_id)
left join folio_derived.users_groups uuin on
	(jsonb_extract_path_text(i.jsonb,
	'metadata',
	'updatedByUserId')::uuid = uuin.user_id)
where
	((jsonb_extract_path_text(i.jsonb,
	'metadata',
	'updatedDate')::date between start_update_date and end_update_date)
		or
(jsonb_extract_path_text(i.jsonb,
		'metadata',
		'createdDate')::date between start_update_date and end_update_date))
	and (uuin.username like update_user)
order by
	jsonb_extract_path_text(i.jsonb,
	'metadata',
	'updatedDate')::date,
	uuin.username,
	it.hrid
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
