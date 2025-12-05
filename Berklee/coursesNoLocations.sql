--metadb:function coursesNoLocations

DROP FUNCTION IF EXISTS coursesNoLocations;

CREATE FUNCTION coursesNoLocations()
RETURNS TABLE
  (course_name text,
  course_number text,
  faculty_name text,
  reserve_location text)
AS $$
select
	cct2.name as course_name,
	cct2.course_number,
	cit."name" as faculty_name,
	lt."name" as reserve_location
from
	folio_courses.coursereserves_courselistings__t cct
left join folio_courses.coursereserves_courses__t cct2 on
	(cct.id = cct2.course_listing_id)
left join folio_inventory.location__t lt on
	(lt.id = cct.location_id)
left join folio_courses.coursereserves_instructors__t cit on
	(cct.id = cit.course_listing_id)
where
	lt.name is null
order by
	cct2.name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
