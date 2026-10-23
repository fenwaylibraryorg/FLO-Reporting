--metadb:function circStatsByDate

DROP FUNCTION IF EXISTS circStatsByDate;

CREATE FUNCTION circStatsByDate(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (title text,
  effective_shelving_order text,
  call_number text,
  enumeration_data text,
  barcode text, 
  loans integer)
AS $$
with total_loans as
  (
  select jsonb_extract_path_text(loan.jsonb, 'itemId') :: uuid as item_id, 
  count(*) as loans
  from folio_circulation.loan
  where jsonb_extract_path_text(loan.jsonb, 'loanDate') ::date between start_date and end_date
  group by item_id
  )
select
	it.title,
	it2.effective_shelving_order,
	hrt.call_number,
	coalesce(it2.enumeration,
	it2.chronology,
	it2.volume) as enumeration_data,
    it2.barcode,
	tl.loans
from
	folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on
	(hrt.instance_id = it.id)
left join folio_inventory.item__t it2 on
	(it2.holdings_record_id = hrt.id)
inner join total_loans tl on (tl.item_id = it2.id)
order by tl.loans desc, it2.effective_shelving_order
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
