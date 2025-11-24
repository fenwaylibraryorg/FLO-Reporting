--metadb:function circCountByUserGroup

DROP FUNCTION IF EXISTS circCountByUserGroup;

CREATE FUNCTION circCountByUserGroup(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  user_group text,
  circ_count integer
  )
AS $$
select
	gt."desc" as user_group,
	count(distinct li.id) as circ_count
from
	folio_circulation.loan__t__ li
left join folio_inventory.item__t it on
	(it.id = li.item_id)
left join folio_users.users__t ut on
	(li.user_id = ut.id)
left join folio_users.groups__t gt on
	(ut.patron_group = gt.id)
where
	li.loan_date between start_date and end_date
group by
	gt."desc"
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
