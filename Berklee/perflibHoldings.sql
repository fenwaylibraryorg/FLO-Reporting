--metadb:function perflibHoldings

DROP FUNCTION IF EXISTS perflibHoldings;

CREATE FUNCTION perflibHoldings()
RETURNS TABLE
  (library_name text,
  effective_call_number text,
  item_hrid text,
  perm_location_name text,
  perm_location_code text,
  barcode text,
  volume text,
  title text,
  contributor_name text,
  publisher text,
  date_of_publication text,
  hrid text,
  instance_uuid uuid,
  opac_link text,
  item_status text,
  material_type_name text,
  instance_opac_suppressed boolean,
  instance_staff_suppressed boolean,
  holdings_suppressed boolean,
  item_suppressed boolean,
  subjects text,
  instance_added timestamp,
  holding_added timestamp,
  item_added timestamp,
  koha_accession_date text
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
  subject_field as (
    select mt.instance_id,   STRING_AGG (mt.content, '; ') as subject
    from folio_source_record.marc__t mt 
    where mt.field LIKE '650' and mt.sf LIKE 'a'
    group by mt.instance_id),
  accession_notes as (
    select in2.item_id,   STRING_AGG (in2.note, '; ') as notes
    from folio_derived.item_notes in2
    where in2.note_type_name LIKE 'Accession Date'
    group by in2.item_id)
select 
  lib.name as library_name,
  ie.effective_call_number, 
  ie.item_hrid,
  lt.name as perm_location_name, 
  lt.code as perm_location_code,
  ie.barcode, 
  ie.volume,
  it.title,
  ic2.contributor_name, 
  ip2.publisher,
  ip2.date_of_publication,
  it.hrid as instance_uuid,
  it.id,
  'https://catalog.berklee.edu/Record/' || it.hrid as opac_link,
  ie.status_name as item_status,
  ie.material_type_name,
  it.discovery_suppress as instance_opac_suppressed,
  it.staff_suppress as instance_staff_suppressed, 
  hrt.discovery_suppress as holdings_suppressed,
  ie.discovery_suppress as item_suppressed,
  sf.subject as subjects,
  inst.creation_date as instance_added, 
  hr.creation_date as holding_added, 
  item.creation_date as item_added,
  acc.notes as koha_accession_date
from folio_derived.item_ext ie 
left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.loclibrary__t__ lib on (lt.library_id = lib.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join inst_publishers ip2 on (it.id = ip2.instance_id) 
left join subject_field sf on (it.id = sf.instance_id)
left join accession_notes acc on (acc.item_id = ie.item_id) 
  /*joining non-transformed versions in order to get creation dates*/
left join folio_inventory.instance inst on (inst.id = it.id)  
left join folio_inventory.holdings_record hr on (hr.id = hrt.id) 
left join folio_inventory.item item on (item.id = ie.item_id) 
where 
  ((it.staff_suppress is false) or (it.staff_suppress is null))
  and (ie.status_name = 'Available') 
  and lib.name = 'Performance Library'
  order by lib.name, ie.effective_location_name, ie.effective_call_number
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
