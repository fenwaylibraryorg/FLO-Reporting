--metadb:function topCircs

DROP FUNCTION IF EXISTS topCircs;

CREATE FUNCTION topCircs(
  start_loan_date date DEFAULT '2000-01-01',
  end_loan_date date DEFAULT '2050-01-01'
)
RETURNS TABLE(
  instance_hrid text,
  title text,
  call_number text, 
  barcode text,
  contributor_name text,
  effective_location text,
  material_type text,
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
  where jsonb_extract_path_text(loan.jsonb, 'loanDate') :: timestamp between start_loan_date and end_loan_date
  group by item_id
  )
select distinct 
  it.hrid as instance_hrid,
  it.title,
  hrt.call_number,
  it2.barcode,
  ic2.contributor_name,  
  lt.name as effective_location, 
  mt.name as material_type, 
  tl.loans
from folio_inventory.instance__t__ it
inner join folio_inventory.holdings_record__t hrt on (hrt.instance_id = it.id)
inner join folio_inventory.item__t it2 on (it2.holdings_record_id = hrt.id)
inner join folio_inventory.location__t lt on (it2.effective_location_id = lt.id) 
inner join folio_inventory.material_type__t__ mt on (it2.material_type_id = mt.id)
inner join inst_contributors ic2 on (it.id = ic2.instance_id)
inner join total_loans tl on (tl.item_id = it2.id)
where tl.loans is not null
order by tl.loans desc
limit 20
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
