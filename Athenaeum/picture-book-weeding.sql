--metadb:function weedingList


DROP FUNCTION IF EXISTS weedingList;

CREATE FUNCTION weedingList()
RETURNS TABLE(
    instance_hrid text,
    barcode text,
    title text,
    contributor_name text,
    call_number text,
    date_acquired text,
    total_folio_loans text,
    voyager_historical_charges text,
    last_checkout text,
    sort_column text
  )
AS $$
with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ),
  item_note as (
  select i.id, notes_json->>'note' as acq_date
  from folio_inventory.item i,
  lateral jsonb_array_elements(i.jsonb->'notes') as notes_json
  where notes_json->>'itemNoteTypeId'='f141829a-d359-473e-b08e-1300835fcff3' 
  ),
  voyager_loans as (
  select i.id, notes_json->>'note' as voyager_total
  from folio_inventory.item i,
  lateral jsonb_array_elements(i.jsonb->'notes') as notes_json
  where notes_json->>'itemNoteTypeId'='31dce827-b01c-438d-9236-74c6368659a3' 
  ),
  total_loans as
  (
  select jsonb_extract_path_text(loan.jsonb, 'itemId') :: uuid as item_id, 
  max(jsonb_extract_path_text(loan.jsonb, 'loanDate')) :: timestamp as "checkout", 
  count(*) as loans
  from folio_circulation.loan
  group by item_id
  )
select distinct it.hrid as instance_hrid,
  it2.barcode,
  it.title,
  ic2.contributor_name,
  hrt.call_number as "call_number",
  itn.acq_date as "date_acquired",
  tl.loans as "total_folio_loans",
  vl.voyager_total as "voyager_historical_charges",
  tl.checkout as "last_checkout",
  i.jsonb->>'effectiveShelvingOrder' as sort_column
from folio_inventory.instance__t__ it
inner join folio_inventory.holdings_record__t hrt on (hrt.instance_id = it.id)
inner join folio_inventory.item__t it2 on (it2.holdings_record_id = hrt.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join item_note itn on (itn.id = it2.id)
left join voyager_loans vl on (vl.id = it2.id)
inner join folio_inventory.item i on (it2.id = i.id)
inner join folio_inventory.location__t lt on (i.effectiveLocationId = lt.id)
inner join total_loans tl on (tl.item_id = it2.id)
where lt.name in ('Childpix')
order by i.jsonb->>'effectiveShelvingOrder' asc
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
