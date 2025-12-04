--metadb:function usersByGroup

DROP FUNCTION IF EXISTS usersByGroup;

CREATE FUNCTION usersByGroup()
RETURNS TABLE
  (group_name text,
  user_count integer)
AS $$
select
	ug.group_name,
	count(ug.user_id) as user_count
from
	folio_derived.users_groups ug
group by
	ug.group_name
order by
	ug.group_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
