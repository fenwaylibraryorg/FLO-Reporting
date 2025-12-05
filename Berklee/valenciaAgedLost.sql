--metadb:function valenciaAgedLost

DROP FUNCTION IF EXISTS valenciaAgedLost;

CREATE FUNCTION valenciaAgedLost()
RETURNS TABLE
  (library_name text,
  effective_call_number text,
  item_hrid text,
  effective_location_name text,
  perm_location_name text,
  perm_location_code text,
  barcode text,
  volume text,
  title text,
  contributor_name text,
  publisher text,
  date_of_publication text,
  instance_hrid text,
  instance_uuid uuid,
  opac_link text,
  item_status text,
  item_status_date date, 
  material_type_name text,
  instance_opac_suppressed boolean,
  instance_staff_suppressed boolean,
  holdings_suppressed boolean,
  item_suppressed boolean
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
  group by ip.instance_id, ip.publisher, ip.date_of_publication)
select distinct
  lib.name as library_name,
  ie.effective_call_number,
  ie.item_hrid,
  ie.effective_location_name,
  lt.name as perm_location_name,
  lt.code as perm_location_code,
  ie.barcode,
  ie.volume,
  it.title,
  ic2.contributor_name,
  ip2.publisher,
  ip2.date_of_publication,
  it.hrid as instance_hrid,
  it.id as instance_uuid,
  'https://catalog.berklee.edu/Record/' || it.hrid as opac_link,
  ie.status_name as item_status,
  date(ie.status_date) as item_status_date,
  ie.material_type_name,
  it.discovery_suppress as instance_opac_suppressed,
  it.staff_suppress as instance_staff_suppressed,
  hrt.discovery_suppress as holdings_suppressed,
  ie.discovery_suppress as item_suppressed
from folio_derived.item_ext ie
left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.loclibrary__t__ lib on (lt.library_id = lib.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join inst_publishers ip2 on (it.id = ip2.instance_id)
where
  (ie.status_name = 'Aged to lost')
  and lib.name = 'Valencia Library'
order by lib.name, ie.effective_location_name, ie.effective_call_number
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
