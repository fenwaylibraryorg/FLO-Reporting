--metadb:function circRenewalsByDate

DROP FUNCTION IF EXISTS circRenewalsByDate;

CREATE FUNCTION circRenewalsByDate(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (location text,
  material_type text,
  loan_action text,
  loan_count integer
  )
AS $$
select
	lt2.name as location,
	mtt.name as material_type,
	lt.action as loan_action,
	count(distinct lt.item_id) as loan_count
from
	folio_circulation.loan__t__ lt /*all loans current or not */
left join folio_inventory.location__t lt2 on
	(lt2.id = lt.item_effective_location_id_at_check_out)
left join folio_inventory.item__t it on
	(it.id = lt.item_id)
left join folio_inventory.material_type__t mtt on
	(it.material_type_id = mtt.id)
where
	(loan_date between start_date and end_date( /*enter month start and end dates*/
	and (lt.action like 'checkedout'
	or lt.action like 'checkedOut%'
	or lt.action like 'dueDate%'
	or lt.action like 'renewed'
	or lt.action like 'renewed%')
group by
	lt2.name,
	mtt.name,
	lt.action
order by
	lt2.name,
	mtt.name,
	lt.action
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
