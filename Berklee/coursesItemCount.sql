--metadb:function coursesItemCount

DROP FUNCTION IF EXISTS coursesItemCount;

CREATE FUNCTION coursesItemCount()
RETURNS TABLE
  (course_name text,
  course_number text,
  section_name text,
  department_name text,
  start_date timestamptz,
  end_date timestamptz,
  instructor_name text,
  term_name text,
  item_count integer
  )
AS $$
with course_reserves as (
  select cct.course_number,
  cct.section_name,
  cct.name as course_name, 
  cdt.name as department_name, 
  ctt.start_date, 
  ctt.end_date, 
  cit.name as instructor_name,
  crt.item_id,
  ctt.name as term_name
  from folio_courses.coursereserves_courses__t cct
  left join folio_courses.coursereserves_departments__t cdt on (cct.department_id = cdt.id)
  left join folio_courses.coursereserves_courselistings__t cct2 on (cct.course_listing_id = cct2.id)
  left join folio_courses.coursereserves_instructors__t cit on (cct2.id = cit.course_listing_id)
  left join folio_courses.coursereserves_terms__t ctt on (cct2.term_id = ctt.id)
  left join folio_courses.coursereserves_reserves__t crt on (cct2.id = crt.course_listing_id)
 )
select cr2.course_name,
  cr2.course_number,
  cr2.section_name,
  cr2.department_name,
  cr2.start_date,
  cr2.end_date,
  cr2.instructor_name,
  cr2.term_name,
  count(ie.item_id) as item_count
from folio_derived.item_ext ie
join course_reserves cr2 on (ie.item_id = cr2.item_id)
group by cr2.course_name,
  cr2.course_number,
  cr2.section_name,
  cr2.department_name,
  cr2.start_date,
  cr2.end_date,
  cr2.instructor_name,
  cr2.term_name
order by 1
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
