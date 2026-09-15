--metadb:function overdueItems

DROP FUNCTION IF EXISTS overdueItems;

CREATE FUNCTION overdueItems()
RETURNS TABLE(
    title text,
    contributor_name text,
    publisher text,
    date_of_publication text,
    effective_call_number text,
    perm_location text,
    effective_location_name text,
    material_type_name text,
    item_barcode text,
    instance text,
    user_last_name text,
    user_first_name text,
    user_barcode text,
    status_name text,
    loan_date text,
    due_date text
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
select distinct it.title, ic2.contributor_name, ip2.publisher, ip2.date_of_publication,
  ie.effective_call_number, lt.name as perm_location, ie.effective_location_name, ie.material_type_name, ie.barcode as item_barcode, 
  it.hrid as instance,
  ug.user_last_name, ug.user_first_name, ug.barcode as user_barcode,
  ie.status_name, lt2.loan_date::date::text, lt2.due_date::date::text
from folio_derived.item_ext ie
left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join inst_publishers ip2 on (it.id = ip2.instance_id) 
left join folio_circulation.loan__t lt2 ON (lt2.item_id = ie.item_id)
left join folio_derived.users_groups ug ON (ug.user_id = lt2.user_id)
where lt2.due_date AT TIME ZONE 'America/New_York' < CURRENT_DATE AT TIME ZONE 'America/New_York' /*due date is earlier than current day*/
order by lt2.due_date::date
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
