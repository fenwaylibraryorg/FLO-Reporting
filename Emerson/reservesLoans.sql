--metadb:function reservesLoans

DROP FUNCTION IF EXISTS reservesLoans;

CREATE FUNCTION reservesLoans(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (material_type_name text,
  index_title text,
  contributor_name text,
  call_number text,
  barcode text,
  temporary_location_name text,
  permanent_location_name text,
  holdings_uuid uuid,
  item_hrid text,
  loans integer,
  course_number text,
  section_name text,
  course_name text,
  department_name text,
  start_date text,
  end_date text,
  instructor_name text)
AS $$
with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ),
  total_loans as
  (
  select jsonb_extract_path_text(loan.jsonb, 'itemId') :: uuid as item_id, 
  count(*) as loans
  from folio_circulation.loan
  where jsonb_extract_path_text(loan.jsonb, 'loanDate') :: date between start_date and end_date
  group by item_id
  ),
 course_reserves as (
  select cct.course_number,
  cct.section_name,
  cct.name as course_name, 
  cdt.name as department_name, 
  ctt.start_date, 
  ctt.end_date, 
  cit.name as instructor_name,
  crt.item_id
  from folio_courses.coursereserves_courses__t cct
  left join folio_courses.coursereserves_departments__t cdt on (cct.department_id = cdt.id)
  left join folio_courses.coursereserves_courselistings__t cct2 on (cct.course_listing_id = cct2.id)
  left join folio_courses.coursereserves_instructors__t cit on (cct2.id = cit.course_listing_id)
  left join folio_courses.coursereserves_terms__t ctt on (cct2.term_id = ctt.id)
  left join folio_courses.coursereserves_reserves__t crt on (cct2.id = crt.course_listing_id)
 ) 
select ie.material_type_name, 
  it.index_title, 
  ic2.contributor_name, 
  hrt.call_number, 
  ie.barcode, 
  ie.temporary_location_name, 
  lt.name as permanent_location_name, 
  hrt.id as holdings_uuid, 
  ie.item_hrid,
  tl.loans,
  cr2.course_number,
  cr2.section_name,
  cr2.course_name,
  cr2.department_name,
  cr2.start_date::date::text,
  cr2.end_date::date::text,
  cr2.instructor_name
from folio_derived.item_ext ie
left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join total_loans tl on (tl.item_id = ie.item_id)
join course_reserves cr2 on (ie.item_id = cr2.item_id)
order by course_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
