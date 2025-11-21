--metadb:function lostItemsPatrons

DROP FUNCTION IF EXISTS lostItemsPatrons;

CREATE FUNCTION lostItemsPatrons(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  title text,
  status_name text, 
  status_date timestamptz,
  effective_shelving_order text,
  effective_location_name text,
  barcode text,
  enumeration_data text,
  user_barcode text,
  username text,
  user_last_name text,
  user_first_name text,
  user_email text,
  group_name text
  )
AS $$
select
	it.title,
	ie.status_name,
	ie.status_date::timestamptz,
	it2.effective_shelving_order,
	ie.effective_location_name,
	ie.barcode,
	coalesce(ie.enumeration,
	ie.chronology,
	ie.volume) as enumeration_data,
	ut.barcode as user_barcode,
	ut.username,
	ug.user_last_name,
	ug.user_first_name, 
  ug.user_email,
  ug.group_name
from
	folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on
	(it.id = hrt.instance_id)
inner join folio_derived.item_ext ie on
	(ie.holdings_record_id = hrt.id)
inner join folio_inventory.item__t it2 on
	(ie.item_id = it2.id)
inner join folio_circulation.loan__t lt on
	(lt.item_id = it2.id)
inner join folio_users.users__t ut on
	(ut.id = lt.user_id)
inner join folio_derived.users_groups ug on
	(ut.id = ug.user_id)
where
	ie.status_name like '%lost%' 
  and ug.group_name in ('FLO User', 'Graduate', 'Student') 
  and start_date <= ie.status_date::timestamptz  AND ie.status_date::timestamptz < end_date
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
