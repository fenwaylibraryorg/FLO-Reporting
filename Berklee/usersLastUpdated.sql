--metadb:function usersLastUpdated

DROP FUNCTION IF EXISTS usersLastUpdated;

CREATE FUNCTION usersLastUpdated()
RETURNS TABLE
  (username text,
  barcode text,
  user_email text,
  external_system_id text,
  updated_date date,
  last_updated_by_user text)
AS $$
select
	distinct ut.username,
	ut.barcode,
	u.jsonb->'personal'->>'email' as user_email,
	ut.external_system_id,
	date(ut.updated_date) as updated_date,
	ut2.username as last_updated_by_user
from
	folio_users.users__t ut
inner join folio_users.users u on
	ut.id = u.id
inner join folio_users.users__t ut2 on
	u.jsonb->'metadata'->>'updatedByUserId' = ut2.id::text
order by updated_date desc
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
