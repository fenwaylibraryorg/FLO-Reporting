--metadb:function circByCallNo

DROP FUNCTION IF EXISTS circByCallNo;

CREATE FUNCTION circByCallNo(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (location_name text,
  Lc_class text,
  count integer)
AS $$
select
	lt.name as location_name,
	rtrim(substring(hrt.call_number
from
	'[A-Z]*')) as Lc_class,
	COUNT(distinct lt2.id)
from
	folio_circulation.loan__t__ lt2
left join folio_inventory.item__t it on
	(it.id = lt2.item_id)
left join folio_inventory.location__t lt on
	(it.effective_location_id = lt.id)
left join folio_inventory.holdings_record__t hrt on
	(it.holdings_record_id = hrt.id)
left join folio_inventory.call_number_type__t cntt on
	(hrt.call_number_type_id = cntt.id)
where
	(lt2.loan_date between start_date and end_date)
	and (cntt.name like 'Library of Congress%'
	or cntt.name like 'LC%')
group by
	lt.name,
	Lc_class
order by
	lt.name,
	Lc_class
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
