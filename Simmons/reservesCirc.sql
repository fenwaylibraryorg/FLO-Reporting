--metadb:function reservesCirc

DROP FUNCTION IF EXISTS reservesCirc;

CREATE FUNCTION reservesCirc(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (circ_count integer)
AS $$
select 
	count (li.loan_id) as circ_count
from 
	folio_derived.loans_items li 
where 
	li.loan_date between start_date and end_date
	and li.item_effective_location_name_at_check_out like '%Reserve%'
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
