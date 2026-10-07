--metadb:function shelflist

DROP FUNCTION IF EXISTS shelflist;

CREATE FUNCTION shelflist(
    start_cn_range text DEFAULT '',
    end_cn_range text DEFAULT '')
RETURNS TABLE(
  bib_hrid text,
  bib_uuid uuid,
  title text,
  suppressed_status text,
  contributor_name text,
  holdings_hrid text,
  call_number text,
  effective_shelving_order text,
  publisher text,
  pub_date text,
  isbn text,
  barcode text,
  overall_loans int,
  folio_loans int,
  item_count int
  )
AS $$
with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ),
    inst_publishers as (
  select ip.instance_id, ip.publisher, ip.date_of_publication
  from folio_derived.instance_publication ip where ip.publication_ordinality='1'
  group by ip.instance_id, ip.publisher, ip.date_of_publication),
    inst_isbn AS (
  select ind.instance_id, STRING_AGG(ind.identifier, ' | '::TEXT) AS isbn
  from folio_derived.instance_identifiers ind
  where ind.identifier_type_name = 'ISBN'
  group by ind.instance_id
),
  millennium_notes AS(
  select i.id, notes_json->>'note' as millennium_total
  from folio_inventory.item i,
  lateral jsonb_array_elements(i.jsonb->'notes') as notes_json
  where notes_json->>'itemNoteTypeId'='c37a19a8-fd40-4567-bd18-5975990dde07' 
),
  total_loans as(
  select jsonb_extract_path_text(loan.jsonb, 'itemId') :: uuid as item_id, 
  count(*) as loans
  from folio_circulation.loan
  group by item_id
),
  item_count as (
  select it2.id, count(itm.id) as item_count
  from folio_inventory.instance__t it2
  left join folio_inventory.holdings_record__t hrt2 on (hrt2.instance_id = it2.id) 
  left join folio_inventory.item__t itm on (hrt2.id = itm.holdings_record_id) 
  group by it2.id)
select 
  it.hrid as bib_hrid,
  it.id as bib_uuid,  
  it.title,
  case when 
  it.discovery_suppress is true then 'SUPPRESSED'
  ELSE 'NOT SUPPRESSED' END AS suppressed_status,
  ic.contributor_name,
  hrt.hrid as holdings_hrid,
  hrt.call_number,
  im.effective_shelving_order,
  ip.publisher,
  REGEXP_SUBSTR(ip.date_of_publication, '\d{4}') as pub_date,
  ib.isbn,
  im.barcode,
  coalesce(mn.millennium_total::int, 0) + coalesce(tl.loans, 0) as overall_loans,
  case when 
  tl.loans is null then 0
  else tl.loans end as folio_loans,
  imc.item_count
from 
folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on (hrt.instance_id = it.id)
left join folio_inventory.item__t im on (im.holdings_record_id = hrt.id) 
left join inst_contributors ic on (ic.instance_id = it.id) 
left join inst_publishers ip on (ip.instance_id = it.id) 
left join inst_isbn ib on (ib.instance_id = it.id) 
left join millennium_notes mn on (mn.id = im.id) 
left join total_loans tl on (tl.item_id = im.id) 
left join item_count imc on (imc.id = it.id) 
where (hrt.call_number between start_cn_range and end_cn_range) and
  it.id not in (select iea.instance_id from folio_derived.instance_electronic_access iea where iea.uri
  is not null) 
order by im.effective_shelving_order, hrt.call_number, it.hrid
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
