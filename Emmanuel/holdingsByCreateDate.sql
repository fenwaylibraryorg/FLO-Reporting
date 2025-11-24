--metadb:function holdingsByCreateDate

DROP FUNCTION IF EXISTS holdingsByCreateDate;

CREATE FUNCTION holdingsByCreateDate(  
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  holdings_hrid text,
  title text,
  call_number text,
  publisher text,
  date_of_publication text,
  barcode text,
  creation_date timestamptz,
  username text,
  user_last_name text,
  user_first_name text
  )
AS $$
select
	distinct hrt.hrid as holdings_hrid,
	it.title,
	hrt.call_number,
	ip.publisher,
	ip.date_of_publication,
	it2.barcode,
	h.creation_date,
	ug.username,
	ug.user_last_name,
	ug.user_first_name
from
	folio_inventory.holdings_record__t hrt
left join folio_inventory.holdings_record h on
	(h.id = hrt.id)
left join folio_inventory.instance__t it on
	(it.id = hrt.instance_id)
left join folio_inventory.item__t it2 on
	(it2.holdings_record_id = hrt.id)
left join folio_inventory.location__t l on
	(l.id = hrt.permanent_location_id)
left join folio_derived.instance_publication ip on
	(ip.instance_id = it.id)
left join folio_derived.users_groups ug on
	(ug.user_id = h.created_by)
where
	h.creation_date between start_date and end_date
order by
	hrt.hrid;
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
