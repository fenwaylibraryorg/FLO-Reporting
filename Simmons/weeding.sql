--metadb:function weeding

DROP FUNCTION IF EXISTS weeding;

CREATE FUNCTION weeding(
    start_loan_date date DEFAULT '2000-01-01',
    end_loan_date date DEFAULT '2050-01-01',
    shelving_location text DEFAULT '%%')
RETURNS TABLE(
  effective_location_name text,
  title text,
  contributor_name text,
  instance_series text,
  edition text,
  isbn text,
  barcode text,
  effective_call_number text,
  item_id uuid,
  status_name text,
  last_check_in date,
  total_checkouts integer,
  total_renewals integer
  )
AS $$
  with 
  total_loans as
  (
  select li2.item_id, 
  li2.renewal_count,
  count(*) as loans
  from folio_derived.loans_items li2
  where li2.loan_date::date between start_loan_date and end_loan_date
  group by item_id, renewal_count
  ),
inst_contributors AS (
  select ic.instance_id, ic.contributor_name
  from 
  folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ),
  inst_isbn AS (
    SELECT
        ind.instance_id,
        STRING_AGG(ind.identifier, ' | '::TEXT) AS isbn
    FROM folio_derived.instance_identifiers ind
    where ind.identifier_type_name = 'ISBN'
    GROUP BY ind.instance_id
)
select 
  ie.effective_location_name,
  i.title,
  ic2.contributor_name,
  jsonb_extract_path_text(isr.series::jsonb, 'value') as instance_series,
  ied.edition,
  isbn.isbn, 
  ie.barcode, 
  ie.effective_call_number,
  ie.item_id,
  ie.status_name,
  max(li.loan_return_date::date) as last_check_in,
  tl.loans as total_checkouts,
  tl.renewal_count as total_renewals
  from
  folio_derived.item_ext ie
  left join folio_inventory.item__t i2 on (ie.item_id = i2.id) 
  left join folio_derived.holdings_ext hrt on (hrt.holdings_id = ie.holdings_record_id)
  left join folio_inventory.instance__t i on (hrt.instance_id = i.id)
  left join folio_derived.instance_series isr on (isr.instance_id = i.id) 
  left join folio_derived.instance_editions ied on (ied.instance_id = i.id) 
  left join total_loans tl on (tl.item_id = ie.item_id)
  left join inst_contributors ic2 on (i.id = ic2.instance_id) 
  left join inst_isbn isbn on (isbn.instance_id = i.id) 
  left join folio_derived.loans_items li on (li.item_id = ie.item_id) 
    where (ie.effective_location_name ilike shelving_location) 
group by ie.effective_location_name, i.title, ic2.contributor_name, isr.series, ied.edition, isbn.isbn, ie.barcode, ie.effective_call_number, ie.item_id, 
  ie.status_name, tl.loans, i2.effective_shelving_order, tl.renewal_count
  order by i2.effective_shelving_order
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
