--metadb:function shelflist

DROP FUNCTION IF EXISTS shelflist;

CREATE FUNCTION shelflist()
RETURNS TABLE
  (effective_call_number text,
  barcode text,
  material_type_name text,
  title text,
  contributor_name text,
  home_library text,
  perm_location text,
  effective_location_name text)
AS $$
with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  )
select distinct ie.effective_call_number, ie.barcode, ie.material_type_name, it.title, ic2.contributor_name, lib.name as home_library, lt.name as perm_location, ie.effective_location_name 
from folio_derived.item_ext ie 
left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.loclibrary__t__ lib on (lt.library_id = lib.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
order by lib.name, ie.effective_location_name, ie.effective_call_number 
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
