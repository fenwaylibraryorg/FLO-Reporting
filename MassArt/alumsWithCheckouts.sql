--metadb:function alumsWithCheckouts

DROP FUNCTION IF EXISTS alumsWithCheckouts;

CREATE FUNCTION alumsWithCheckouts()
RETURNS TABLE(
    user_id uuid,
    barcode text,
    user_last_name text,
    user_first_name text,
    group_name text,
    item_hrid text
  )
AS $$
select 
  ug.user_id,
  ug.barcode,
  ug.user_last_name,
  ug.user_first_name, 
  ug.group_name,
  ie.item_hrid
  from
  folio_derived.loans_items li
  left join folio_derived.users_groups ug on (li.user_id = ug.user_id) 
  left join folio_inventory.item__t it on (it.id = li.item_id)
  left join folio_inventory.holdings_record__t hrt on (hrt.id = it.holdings_record_id)
  left join folio_inventory.instance__t it2 on (it2.id = hrt.instance_id)
  left join folio_derived.item_ext ie on (ie.item_id = li.item_id)
  where li.loan_return_date is null and ug.group_name = 'Alum'
  order by ug.user_last_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
