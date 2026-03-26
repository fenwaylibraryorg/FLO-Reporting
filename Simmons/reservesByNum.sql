--metadb:function reservesByNum

DROP FUNCTION IF EXISTS reservesByNum;

CREATE FUNCTION reservesByNum(
    course_num text DEFAULT '%%',
    instructor_name text DEFAULT '%%')
RETURNS TABLE(
  course_number text,
  section_name text,
  course_name text,
  instructor text,
  title text,
  barcode text,
  item_hrid text,
  OPAC_link text
  )
AS $$
select
	cct.course_number,
	cct.section_name as course_name,
	cct.name,
    cit."name" as instructor,
    ie2.title,
    ie.barcode,
    ie.item_hrid,
    'https://catalog.berklee.edu/Record/' || ie2.instance_hrid "OPAC_link"
from
	folio_courses.coursereserves_courses__t cct
left join folio_courses.coursereserves_courselistings__t cct2 on
	(cct.course_listing_id = cct2.id)
left join folio_courses.coursereserves_reserves__t crt on
	(crt.course_listing_id = cct2.id)
left join folio_courses.coursereserves_courselistings cc on
	(cc.id = cct2.id)
left join folio_courses.coursereserves_instructors__t cit on 
  (cit.course_listing_id = cc.id) 
left join folio_derived.item_ext ie on 
  (ie.item_id = crt.item_id) 
left join folio_derived.holdings_ext he on 
  (he.holdings_id = ie.holdings_record_id)
left join folio_derived.instance_ext ie2 on 
  (ie2.instance_id = he.instance_id) 
where cct.course_number like course_num and cit.name like instructor_name
order by cct.course_number, cct.section_name, instructor, ie2.title
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
