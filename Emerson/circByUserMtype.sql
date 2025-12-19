--metadb:function circByUserMtype

DROP FUNCTION IF EXISTS circByUserMtype;

CREATE FUNCTION circByUserMtype(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (user_group text,
  material_type text,
  loan_action text,
  loan_count integer
  )
AS $$
select
	gt.group as user_group,
	mtt.name as material_type,
	lt.action as loan_action,
	count(distinct lt.id) as loan_count 
from
	folio_circulation.loan__t__ lt /*all loans*/
left join folio_users.users__t__ ut on
	(lt.user_id = ut.id)
left join folio_users.groups__t gt on
	(gt.id = ut.patron_group)
left join folio_inventory.item__t it on
	(it.id = lt.item_id)
left join folio_inventory.material_type__t mtt on
	(mtt.id = it.material_type_id)
where
	(lt.loan_date between start_date and end_date) /*dates start and end dates*/
	and (lt.action like 'checkedout'
	or lt.action like 'checkedOut%'
	or lt.action like 'dueDate%')
group by
	gt.group,
	mtt.name,
	lt.action
order by
	gt.group,
	mtt.name,
	lt.action
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
