--metadb:function locationMismatch

DROP FUNCTION IF EXISTS locationMismatch;

CREATE FUNCTION locationMismatch()
RETURNS TABLE(
    instance_hrid text,
    instance_suppress bool,
    contributor_name text,
    index_title text,
    publisher text,
    publisher_place text,
    date_of_publication text,
    holdings_hrid text,
    holdings_suppress bool,
    call_no text,
    holdings_location text,
    public_note text,
    holdings_statement text,
    item_hrid text,
    barcode text,
    item_location text,
    item_temp_location text,
    item_type text,
    items_per_holding integer,
    unmatched_items_per_holding integer
  )
AS $$
with
    inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ),
    inst_publishers as (
  select ip.instance_id, ip.publisher, ip.date_of_publication, ip.publication_place
  from folio_derived.instance_publication ip where ip.publication_ordinality='1'
  group by ip.instance_id, ip.publisher, ip.date_of_publication, ip.publication_place),
    item_count as (select hrt.id, count(itm.id) as item_count
  from folio_inventory.holdings_record__t hrt
  left join folio_inventory.item__t itm on (hrt.id = itm.holdings_record_id) 
  group by hrt.id),
  non_matches as (select hrt.id, count(itm.id) as item_count
  from folio_inventory.holdings_record__t hrt
  left join folio_inventory.item__t itm on (hrt.id = itm.holdings_record_id) 
  left join folio_inventory.location__t loc_hrt on (hrt.permanent_location_id = loc_hrt.id) 
  left join folio_inventory.location__t loc_itm on (loc_itm.id = itm.permanent_location_id) 
  where itm.permanent_location_id <> hrt.permanent_location_id
  group by hrt.id),
  hrt_notes as (select hn.holding_id, hn.note
  from
  folio_derived.holdings_notes hn
  where hn.note_type_name = 'Note'
  ),
  hrt_statements as (
  select hs.holdings_id, STRING_AGG(hs.holdings_statement, ' | '::TEXT) as holdings_statement
  from
  folio_derived.holdings_statements hs
  where hs.holdings_statement is not null 
  group by hs.holdings_id
  )
select 
  ist.hrid as instance_hrid,
  ist.discovery_suppress as instance_suppress,
  cb.contributor_name,
  ist.index_title,
  pb.publisher,
  pb.publication_place, 
  pb.date_of_publication,
  hrt.hrid as holdings_hrid,
  hrt.discovery_suppress as holdings_suppress,
  concat(hrt.call_number_prefix,' ', hrt.call_number) as call_no,
  loc_hrt."name" as holdings_location,
  hrn.note as public_note,
  hrs.holdings_statement, 
  itm.hrid as item_hrid,
  itm.barcode,
  loc_itm."name" as item_location,
  loc_temp_itm."name" as item_temp_location,
  mt."name" as item_type,
  ic.item_count as items_per_holding,
  nm.item_count as unmatched_items_per_holding
from 
folio_inventory.instance__t ist
left join folio_inventory.holdings_record__t hrt on (hrt.instance_id = ist.id) 
left join hrt_notes hrn on (hrn.holding_id = hrt.id) 
left join hrt_statements hrs on (hrs.holdings_id = hrt.id) 
left join folio_inventory.location__t loc_hrt on (hrt.permanent_location_id = loc_hrt.id) 
left join folio_inventory.item__t itm on (itm.holdings_record_id = hrt.id) 
left join folio_inventory.location__t loc_itm on (loc_itm.id = itm.permanent_location_id) 
left join folio_inventory.location__t loc_temp_itm on (loc_temp_itm.id = itm.temporary_location_id) 
left join folio_inventory.material_type__t mt on (itm.material_type_id = mt.id) 
left join inst_contributors cb on (cb.instance_id = ist.id) 
left join inst_publishers pb on (pb.instance_id = ist.id)  
left join item_count ic on (ic.id = hrt.id) 
left join non_matches nm on (nm.id = hrt.id) 
where itm.permanent_location_id <> hrt.permanent_location_id
order by ist.hrid, concat(hrt.call_number_prefix,' ', hrt.call_number)
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
