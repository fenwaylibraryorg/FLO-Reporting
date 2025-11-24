--metadb:function userExpDate

DROP FUNCTION IF EXISTS userExpDate;

CREATE FUNCTION userExpDate(
    user_group text DEFAULT '')
RETURNS TABLE(
  user_last_name text,
  user_first_name text,
  username text,
  group_name text,
  created_date date,
  expiration_date date,
  user_status text 
  )
AS $$
SELECT 
  ug.user_last_name,
  ug.user_first_name,
  ug.username,
  ug.group_name,
  ug.created_date::date,
  ug.expiration_date::date,
  CASE WHEN 
  ug.active = TRUE THEN 'Active'
  ELSE 'Inactive'
  END AS "user_status"
FROM
folio_derived.users_groups ug
where ug.group_name = user_group
order by ug.user_last_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
