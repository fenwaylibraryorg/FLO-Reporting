--metadb:function reservesCircByDay

DROP FUNCTION IF EXISTS reservesCircByDay;

CREATE FUNCTION reservesCircByDay(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (loan_date text,
  loan_count integer)
AS $$
select 
	li.loan_date::date::text, count (li.loan_id) as loan_count
from 
	folio_derived.loans_items li 
where 
	li.loan_date between start_date and end_date
	and li.item_effective_location_name_at_check_out like '%Reserve%'
group by li.loan_date::date::text
order by li.loan_date::date::text
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
