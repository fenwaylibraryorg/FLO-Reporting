--metadb:function shelflist

DROP FUNCTION IF EXISTS shelflist;

CREATE FUNCTION shelflist(
    start_cn_range text DEFAULT '',
    end_cn_range text DEFAULT '')
RETURNS TABLE(
  title text,
  barcode text,
  copy_number text,
  effective_call_number text,
  effective_location_name text,
  effective_shelving_order text
  )
AS $$
with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  )
select 
  it.title, 
  ie.barcode, 
  ie.copy_number,
  ie.effective_call_number, 
  ie.effective_location_name,
  regexp_replace(im.effective_shelving_order,'\.','Z') as effective_shelving_order
from folio_derived.item_ext ie 
left join folio_inventory.item__t im on (im.id = ie.item_id) 
left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.loclibrary__t__ lib on (lt.library_id = lib.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
where ie.effective_call_number between start_cn_range and end_cn_range
order by regexp_replace(im.effective_shelving_order,'\.','Z')
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
