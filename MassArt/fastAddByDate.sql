--metadb:function fastAddByDate

DROP FUNCTION IF EXISTS fastAddByDate;

CREATE FUNCTION fastAddByDate(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  title text,
  contributor_name text,
  publisher text,
  date_of_publication text,
  barcode text,
  material_type_name text,
  created_date timestamptz,
  created_by text 
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
select
  it.title,
  ic2.contributor_name, 
  ip2.publisher,
  ip2.date_of_publication,
  ie.barcode, 
  ie.material_type_name, 
  ie.created_date,
  ug.username as "created_by"
from folio_derived.holdings_ext hrt
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join folio_derived.item_ext ie on (ie.holdings_record_id = hrt.holdings_id) 
left join folio_inventory.item it2 on (ie.item_id = it2.id) 
left join folio_derived.users_groups ug on (it2.created_by = ug.user_id) 
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join inst_publishers ip2 on (it.id = ip2.instance_id)
where it.source = 'FOLIO' and ie.created_date between start_date and end_date
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
