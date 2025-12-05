DROP FUNCTION IF EXISTS usersNoEmail;

CREATE FUNCTION usersNoEmail()
RETURNS TABLE
  (user_last_name text,
  user_first_name text,
  group_name text,
  external_system_id text,
  expiration_date timestamptz,
  username text,
  barcode text,
  email text)
AS $$
select
	ug.user_last_name,
	ug.user_first_name,
	ug.group_name,
	ug.external_system_id,
	ug.expiration_date,
	ug.username,
	ug.barcode,
	ug.user_email
from
	folio_derived.users_groups ug
where
	((ug.user_email is null)
		or (ug.user_email = ''))
	and ((ug.active is true)
		and (ug.group_name <> 'ComCat'))
order by
	ug.user_last_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
