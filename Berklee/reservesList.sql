--metadb:function reservesList

DROP FUNCTION IF EXISTS reservesList;

CREATE FUNCTION reservesList()
RETURNS TABLE
  (instance_id uuid,
  barcode text,
  title text,
  call_number text,
  material_type_name text,
  effective_location_name text,
  course_name text,
  course_number text,
  section_name text,
  department_name text,
  start_date timestamptz,
  end_date timestamptz,
  instructor_name text,
  term_name text,
  course_type text)
AS $$
with course_reserves as (
  select distinct cct.course_number,
  cct.section_name,
  cct.name as course_name, 
  cdt.name as department_name, 
  ctt.start_date, 
  ctt.end_date, 
  cit.name as instructor_name,
  crt.item_id,
  ctt.name as term_name,
  cctypes.name course_type
  from folio_courses.coursereserves_courses__t cct
  left join folio_courses.coursereserves_departments__t cdt on (cct.department_id = cdt.id)
  left join folio_courses.coursereserves_courselistings__t cct2 on (cct.course_listing_id = cct2.id)
  left join folio_courses.coursereserves_instructors__t cit on (cct2.id = cit.course_listing_id)
  left join folio_courses.coursereserves_terms__t ctt on (cct2.term_id = ctt.id)
  left join folio_courses.coursereserves_reserves__t crt on (cct2.id = crt.course_listing_id)
  left join folio_courses.coursereserves_coursetypes__t cctypes on (cctypes.id = cct2.course_type_id)
 )
select distinct it.id as instance_id,
  ie.barcode,
  it.title,
  hrt.call_number, 
  ie.material_type_name,
  ie.effective_location_name,
  cr2.course_name,
  cr2.course_number,
  cr2.section_name,
  cr2.department_name,
  cr2.start_date,
  cr2.end_date,
  cr2.instructor_name,
  cr2.term_name,
  cr2.course_type
from folio_derived.item_ext ie
join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
join folio_inventory.instance__t it on (hrt.instance_id = it.id)
join course_reserves cr2 on (ie.item_id = cr2.item_id)
order by course_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
