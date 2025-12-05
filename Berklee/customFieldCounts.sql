--metadb:function customFieldCounts

DROP FUNCTION IF EXISTS customFieldCounts;

CREATE FUNCTION customFieldCounts()
RETURNS TABLE
  (group_name text,
  count_power_campus_id integer,
  count_colleague_id integer
  )
AS $$
select 
  ug.group_name,
  count(jsonb_extract_path_text(u."jsonb", 'customFields', 'legacypowercampusid')) as count_power_campus_id,
  count(jsonb_extract_path_text(u."jsonb", 'customFields', 'legacycolleagueid')) as count_colleague_id
from 
folio_derived.users_groups ug 
left join folio_users.users u on (u.id = ug.user_id)
where jsonb_extract_path_text(u."jsonb", 'customFields', 'legacycolleagueid') is not null OR
  jsonb_extract_path_text(u."jsonb", 'customFields', 'legacypowercampusid') is not null
group by ug.group_name
order by ug.group_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
