--metadb:function weedingNoCirc

DROP FUNCTION IF EXISTS weedingNoCirc;

CREATE FUNCTION weedingNoCirc(
    start_call_no text DEFAULT '',
    end_call_no text DEFAULT '')
RETURNS TABLE(
    title text,
    barcode text,
    contributor_name text,
    publisher text,
  date_of_publication text,
  effective_call_number text,
  volume text,
  effective_location_name text,
  created_date timestamptz,
  folio_charges integer,
  voyager_charges text
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
  ie.barcode,
  ic2.contributor_name, 
  ip2.publisher,
  ip2.date_of_publication,
  ie.effective_call_number, 
  ie.volume,
  ie.effective_location_name,
  ie.created_date,
  count(li.id) as "folio_charges",
  io.note as "voyager_charges"
from folio_derived.item_ext ie 
left join folio_inventory.item__t it2 on (ie.item_id = it2.id) 
left join folio_derived.item_notes io on (ie.item_id = io.item_id) 
left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join inst_publishers ip2 on (it.id = ip2.instance_id)
left join folio_circulation.loan__t__ li on (li.item_id = ie.item_id)
where io.note_type_name = 'Voyager Historical Charges' and io.note = '0' 
  and ie.effective_location_name = 'Main Stacks' and ie.effective_call_number between start_call_no and end_call_no
group by   it.title, ie.barcode, ic2.contributor_name, ip2.publisher, ip2.date_of_publication, it2.effective_shelving_order, ie.effective_call_number, ie.volume, ie.effective_location_name, ie.created_date, io.note
having count(li.id) = 0  
order by it2.effective_shelving_order
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
