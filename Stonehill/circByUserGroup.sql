--metadb:function circByUserGroup

DROP FUNCTION IF EXISTS circByUserGroup;

CREATE FUNCTION circByUserGroup(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (user_group text,
  circ_count integer)
AS $$
select coalesce(gt."group", 'Total Circs') AS user_group, count(lt.action) as circ_count
  from folio_circulation.loan__t__ lt
  left join folio_users.users__t ut ON (lt.user_id = ut.id)
  left join folio_users.groups__t gt ON (ut.patron_group = gt.id)
where start_date <= lt.loan_date AND lt.loan_date <= end_date
  and lt.action in ('checkedout','renewed','renewedThroughOverride','checkedOutThroughOverride','dueDateChanged')
group by ROLLUP (gt.group)
order by gt."group" NULLS last
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
