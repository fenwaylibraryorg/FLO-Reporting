--metadb:function TBMR

DROP FUNCTION IF EXISTS TBMR;

CREATE FUNCTION TBMR()
RETURNS TABLE(
  bib_hrid text,
  call_number text,
  title text,
  publication_place text,
  publisher text,
  date_of_publication text,
  effective_shelving_location text,
  contributor_name text,
  vufind_link text,
  holdings_hrid text,
  items_per_holdings integer 
  )
AS $$
 with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ),
    item_count as (select hrt.id, count(itm.id) as item_count
  from folio_inventory.holdings_record__t hrt
  left join folio_inventory.item__t itm on (hrt.id = itm.holdings_record_id) 
  group by hrt.id),
  inst_publishers as (
  select ip.instance_id, ip.publisher, ip.date_of_publication, ip.publication_place
  from folio_derived.instance_publication ip where ip.publication_ordinality='1'
  group by ip.instance_id, ip.publisher, ip.date_of_publication, ip.publication_place)
select 
  it.hrid as bib_hrid,
  hrt.call_number,  
  it.title,
  pb.publication_place,
  pb.publisher,
  pb.date_of_publication,
  lt.name as effective_shelving_location,
  ic2.contributor_name,
  CONCAT('https://catalog.bostonathenaeum.org/Record/', it.hrid) as vufind_link,
  hrt.hrid as holdings_hrid,
  ic.item_count as items_per_holdings
from folio_inventory.instance__t it
inner join folio_inventory.holdings_record__t hrt on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
inner join folio_inventory.location__t lt on (hrt.effective_location_id = lt.id)
left join inst_publishers pb on (pb.instance_id = it.id)  
left join item_count ic on (ic.id = hrt.id) 
where lt.name in ('TBMR') and hrt.call_number like '⁰%'
order by hrt.call_number, it.hrid 
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
