--metadb:function titleListTRs

DROP FUNCTION IF EXISTS titleListTRs;

CREATE FUNCTION titleListTRs(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  title text,
  contributor_name text,
  publisher text,
  date_of_publication text,
  call_number text,
  permanent_location_name text,
  holdings_hrid text, 
  created_date date
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
  hrt.call_number, 
  hrt.permanent_location_name,
  hrt.holdings_hrid,
  hrt.created_date::date
from folio_derived.holdings_ext hrt
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join inst_publishers ip2 on (it.id = ip2.instance_id)
where hrt.call_number like 'TR%' and hrt.created_date between start_date and end_date
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
