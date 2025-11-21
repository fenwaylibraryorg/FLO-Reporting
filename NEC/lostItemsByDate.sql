--metadb:function lostItemsByDate

DROP FUNCTION IF EXISTS lostItemsByDate;

CREATE FUNCTION lostItemsByDate(  
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  title text,
  barcode text,
  due_date timestamptz,
  status_name text,
  status_date timestamptz,
  user_first_name text,
  user_last_name text,
  username text,
  user_barcode text,
  group_description text
  )
AS $$
select it2.title, ie.barcode, lt.due_date, ie.status_name, ie.status_date::timestamptz, ug.user_first_name, ug.user_last_name, ug.username, ug.barcode as user_barcode, ug.group_description 
from folio_circulation.loan__t lt
  left join folio_derived.item_ext ie ON (ie.item_id = lt.item_id)
  left join folio_derived.users_groups ug on (ug.user_id = lt.user_id)
  left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
  left join folio_inventory.instance__t it2 on (hrt.instance_id = it2.id)
where start_date <= ie.status_date::timestamptz  AND ie.status_date::timestamptz <= end_date
  and ie.status_name LIKE 'Aged to lost'
order by ie.status_date desc
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
