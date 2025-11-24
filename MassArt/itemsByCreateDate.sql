--metadb:function itemsByCreateDate

DROP FUNCTION IF EXISTS itemsByCreateDate;

CREATE FUNCTION itemsByCreateDate(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
    username text,
    title text,
    call_number text,
    material_type_name text,
    created_date date,
    effective_location_name text)
AS $$
select
  ug.username,
  it.title,
  hrt.call_number, 
  ie.material_type_name,
  ie.created_date::date,
  ie.effective_location_name
from folio_derived.holdings_ext hrt
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join folio_derived.item_ext ie on (ie.holdings_record_id = hrt.holdings_id) 
left join folio_inventory.item im on (im.id = ie.item_id) 
left join folio_derived.users_groups ug on (im.created_by = ug.user_id) 
left join folio_inventory.item__t it2 on (ie.item_id = it2.id) 
where ie.created_date between start_date and end_date
order by it2.effective_shelving_order
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
