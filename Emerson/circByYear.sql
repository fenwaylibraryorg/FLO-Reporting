--metadb:function circByYear

DROP FUNCTION IF EXISTS circByYear;

CREATE FUNCTION circByYear(
    loan_count integer DEFAULT 0,
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(item_id uuid,
  title text,
  call_number text,
  loan_count integer,
  date_of_publication text 
  )
AS $$
select
	distinct on
	(it.id) it.id as item_id,
	it2.title,
	hrt.call_number,
	count(distinct lt.id) as loan_count,
	ip.date_of_publication
from
	folio_inventory.item__t__ it
left join folio_inventory.holdings_record__t__ hrt on
	(hrt.id = it.holdings_record_id)
left join folio_inventory.instance__t__ it2 on
	(it2.id = hrt.instance_id)
left join folio_derived.instance_publication ip on
	(it2.id = ip.instance_id)
left join folio_circulation.loan__t__ lt on
	(it.id = lt.item_id)
where
	loan_date BETWEEN start_date and end_date
	and it.temporary_location_id != '02676066-4175-402e-884f-9bb1fc51fc2a'
	or it.temporary_location_id is null 
/* not on reserve */
group by
	it.id,
	it2.title,
	hrt.call_number,
	ip.date_of_publication
having
	count(distinct lt.id) >= loan_count /*enter the minimum number of loans*/
order by
	it.id, it2.title asc
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
