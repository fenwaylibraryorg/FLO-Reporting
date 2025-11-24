--metadb:function overdueItems

DROP FUNCTION IF EXISTS overdueItems;

CREATE FUNCTION overdueItems(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  title text,
  barcode text,
  due_date timestamptz,
  user_first_name text,
  user_last_name text,
  username text,
  user_barcode text,
  group_description text
  )
AS $$
select
	it2.title,
	it.barcode,
	lt.due_date,
	ug.user_first_name,
	ug.user_last_name,
	ug.username,
	ug.barcode as user_barcode,
	ug.group_description
from
	folio_circulation.loan__t lt
left join folio_derived.users_groups ug on
	(ug.user_id = lt.user_id)
left join folio_inventory.item__t it on
	(lt.item_id = it.id)
left join folio_inventory.holdings_record__t hrt on
	(it.holdings_record_id = hrt.id)
left join folio_inventory.instance__t it2 on
	(hrt.instance_id = it2.id)
where
	lt.due_date between start_date and end_date
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
