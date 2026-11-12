--metadb:function circCounts

DROP FUNCTION IF EXISTS circCounts;

CREATE FUNCTION circCounts(  
  start_checkout_date date DEFAULT '2000-01-01',
  end_checkout_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  user_group text,
  material_type text,
  circ_count integer,
  item_effective_location text 
  )
AS $$
select
	gt."group" as user_group,
    mt."name" as material_type,
	count(distinct lt.id) as circ_count,
    lt2."name" as item_effective_location
from
	folio_circulation.loan__t lt
left join folio_users.groups__t gt on
	(lt.patron_group_id_at_checkout = gt.id)
left join folio_inventory.item__t it on
    (lt.item_id = it.id) 
left join folio_inventory.material_type__t mt on 
    (it.material_type_id = mt.id) 
left join folio_inventory.location__t lt2 on 
    (lt.item_effective_location_id_at_check_out = lt2.id) 
where
	(lt.loan_date at TIME zone 'America/New_York') :: date >= start_checkout_date /*start=first day of month*/
	and (lt.loan_date at TIME zone 'America/New_York') :: date <= end_checkout_date /*end=first day of next month*/
group by
	mt.name, lt2."name", gt."group"
order by
	gt."group", mt."name", lt2."name"
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
