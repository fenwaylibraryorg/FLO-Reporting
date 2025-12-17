--metadb:function reservesCount

DROP FUNCTION IF EXISTS reservesCount;

CREATE FUNCTION reservesCount()
RETURNS TABLE
  (course_number text,
  section_name text,
  course_name text,
  instructor text,
  reserves_count integer
  )
AS $$
select
	cct.course_number,
	cct.section_name,
	cct.name as course_name,
	jsonb_extract_path_text(jsonb_array_elements(jsonb_extract_path(cc.jsonb,
	'instructorObjects')),
	'name') as instructor,
	count(crt.item_id) as reserves_count
from
	folio_courses.coursereserves_courses__t cct
left join folio_courses.coursereserves_courselistings__t cct2 on
	(cct.course_listing_id = cct2.id)
left join folio_courses.coursereserves_reserves__t crt on
	(crt.course_listing_id = cct2.id)
left join folio_courses.coursereserves_courselistings cc on
	(cc.id = cct2.id)
group by
	cct.course_number,
	cct.section_name,
	cct.name,
	jsonb_extract_path_text(jsonb_array_elements(jsonb_extract_path(cc.jsonb,
	'instructorObjects')),
	'name')
order by
	cct.course_number
 $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
