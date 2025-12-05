--metadb:function userLoadNotUpdated

DROP FUNCTION IF EXISTS userLoadNotUpdated;

CREATE FUNCTION userLoadNotUpdated()
RETURNS TABLE
  (updated_date date,
  lastName text,
  firstName text,
  email text,
  username text,
  external_system_id text,
  barcode text,
  user_group text,
  expiration_date date
  )
AS $$
select
	distinct date(ut2.updated_date) as updated_date,
	u2.jsonb->'personal'->>'lastName' as lastName,
	u2.jsonb->'personal'->>'firstName' as firstName,
	u2.jsonb->'personal'->>'email' as email,
	ut2.username,
	ut2.external_system_id,
	ut2.barcode,
	gt."group" as user_group,
	ut2.expiration_date::date
from
	folio_users.users__t ut2
inner join folio_users.users u2 on
	ut2.id = u2.id
inner join folio_users.groups__t gt on
	ut2.patron_group = gt.id
where
	ut2.updated_date < 
  (
	select
		max(to_timestamp(u.jsonb->'metadata'->>'updatedDate', 'YYYY-MM-DD"T"HH24:MI:SS')) - interval '1 day'
	from
		folio_users.users u
	inner join folio_users.users__t ut on
		u.jsonb->'metadata'->>'updatedByUserId' = ut.id::text
	where
		ut.username = 'flo-api')
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
