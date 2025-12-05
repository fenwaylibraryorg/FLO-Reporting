--metadb:function lostItems

DROP FUNCTION IF EXISTS lostItems;

CREATE FUNCTION lostItems(
    lost_status text DEFAULT '')
RETURNS TABLE(
  home_library text,
  perm_location text,
  effective_location_name text,
  material_type_name text,
  effective_call_number text,
  barcode text,
  contributor_name text,
  title text,
  loan_count integer,
  status_name text,
  lost_date text
  )
AS $$
with
inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ),
total_loans as
  (
  select jsonb_extract_path_text(loan.jsonb, 'itemId') :: uuid as item_id, 
  count(*) as loans
  from folio_circulation.loan
  group by item_id
  )
select lib.name as home_library, lt.name as perm_location, ie.effective_location_name, ie.material_type_name, ie.effective_call_number, ie.barcode, ic2.contributor_name, it.title, tl.loans as loan_count, ie.status_name, ie.status_date as lost_date 
from folio_derived.item_ext ie
left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.loclibrary__t__ lib on (lt.library_id = lib.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join total_loans tl on (tl.item_id = ie.item_id)
where ie.status_name = lost_status
order by lib.name, lt.name, ie.effective_location_name, ie.material_type_name, ie.effective_call_number 
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
