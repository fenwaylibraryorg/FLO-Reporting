--metadb:function circByUserGroup

DROP FUNCTION IF EXISTS circByUserGroup;

CREATE FUNCTION circByUserGroup(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (user_group text,
  loan_count integer
  )
AS $$
select
	gt.group as user_group,
	count(distinct lt.id) as loan_count
from
	folio_circulation.loan__t__ lt /*all loans current or not*/
left join folio_users.users__t__ ut on
	(lt.user_id = ut.id)
left join folio_users.groups__t gt on
	(gt.id = ut.patron_group)
where
	lt.loan_date between start_date and end_date /*enter month start and end dates*/
group by
	gt.group
order by
	gt.group
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
