--metadb:function reserveCircs

DROP FUNCTION IF EXISTS reserveCircs;

CREATE FUNCTION reserveCircs(  
  loan_start date DEFAULT '2000-01-01',
  loan_end date DEFAULT '2050-01-01')
RETURNS TABLE(
  course_name text,
  instructor_name text,
  title text,
  call_number text,
  barcode text,
  material_type_name text,
  loans integer
  )
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
  where jsonb_extract_path_text(loan.jsonb, 'loanDate') :: date between loan_start and loan_end
  group by item_id
  ),
 course_reserves as (
  select cct.course_number, 
  cct.name as course_name, 
  cdt.name as department_name, 
  ctt.start_date, 
  ctt.end_date, 
  cit.name as instructor_name,
  crt.item_id
  from folio_courses.coursereserves_courses__t cct
  left join folio_courses.coursereserves_departments__t cdt on (cct.department_id::uuid = cdt.id::uuid)
  left join folio_courses.coursereserves_courselistings__t cct2 on (cct.course_listing_id::uuid = cct2.id::uuid)
  left join folio_courses.coursereserves_instructors__t cit on (cct2.id::uuid = cit.course_listing_id::uuid)
  left join folio_courses.coursereserves_terms__t ctt on (cct2.term_id::uuid = ctt.id::uuid)
  left join folio_courses.coursereserves_reserves__t crt on (cct2.id::uuid = crt.course_listing_id::uuid)
 )
select 
  cr2.course_name,
  cr2.instructor_name,
  it.title,
  hrt.call_number, 
  ie.barcode, 
  ie.material_type_name, 
  tl.loans
from folio_derived.item_ext ie
left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join total_loans tl on (tl.item_id::uuid = ie.item_id::uuid)
join course_reserves cr2 on (ie.item_id::uuid = cr2.item_id::uuid)
order by course_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
