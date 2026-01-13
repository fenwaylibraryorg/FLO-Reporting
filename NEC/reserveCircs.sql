--metadb:function reserveCircs

DROP FUNCTION IF EXISTS reserveCircs;

CREATE FUNCTION reserveCircs(  
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  course_name text,
  instructor_name text,
  title text,
  call_number text,
  barcode text,
  material_type_name text,
  circ_count integer
  )
AS $$
select 
  cct.name as course_name,
  jsonb_extract_path_text(jsonb_array_elements(jsonb_extract_path(cc.jsonb,
	'instructorObjects')),
	'name') as instructor_name,
  ie.title,
  he.call_number,
  li.barcode,
  li.material_type_name,
  count (distinct li.loan_id) as circ_count
from 
	folio_derived.loans_items li 
  left join folio_derived.holdings_ext he on (he.holdings_id = li.holdings_record_id)
  left join folio_derived.instance_ext ie on (ie.instance_id = he.instance_id) 
  left join folio_courses.coursereserves_reserves__t crt on (crt.item_id::uuid = li.item_id) 
  left join folio_courses.coursereserves_courselistings cc on (crt.course_listing_id::uuid = cc.id) 
  left join folio_courses.coursereserves_courses__t cct on (cct.course_listing_id::uuid = cc.id)
where 
	li.loan_date between start_date and end_date
	and li.item_effective_location_name_at_check_out like '%Reserve%'
group by cct.name, instructor_name, li.barcode, ie.title, he.call_number, li.material_type_name
order by course_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
