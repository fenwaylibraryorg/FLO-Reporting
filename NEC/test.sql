--metadb:function test

DROP FUNCTION IF EXISTS test;

CREATE FUNCTION test(  
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  title text,
  call_number text,
  barcode text,
  material_type_name text,
  circ_count integer 
  )
AS $$
select 
  ie.title,
  he.call_number,
  li.barcode,
  li.material_type_name,
  count (distinct li.loan_id) as circ_count
from 
	folio_derived.loans_items li 
  left join folio_derived.holdings_ext he on (he.holdings_id = li.holdings_record_id)
  left join folio_derived.instance_ext ie on (ie.instance_id = he.instance_id) 
where 
	li.loan_date::date between start_date and end_date
	and li.item_effective_location_name_at_check_out like '%Reserve%'
group by li.barcode, ie.title, he.call_number, li.material_type_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
