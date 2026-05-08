--metadb:function userFinesOver20

DROP FUNCTION IF EXISTS userFinesOver20;

CREATE FUNCTION userFinesOver20()
RETURNS TABLE
  (user_group text,
  last_name text,
  first_name text,
  user_email text,
  username text,
  user_barcode text,
  balance text)
AS $$
select 
	ug.group_name as "Patron Group",
	ug.user_last_name as "Last Name",
	ug.user_first_name as "First Name",
	ug.user_email as "Email",
	ug.username,
	ug.barcode as "Patron Barcode",
	concat('$', sum(at2.remaining)) as "Balance Owed"
from
	folio_derived.users_groups ug
inner join folio_feesfines.accounts__t at2 on ug.user_id=at2.user_id
where at2.remaining>0 
group by
	ug.group_name,
	ug.user_last_name,
	ug.user_first_name,
	ug.user_email,
	ug.username,
	ug.barcode
having
	sum(at2.remaining) >= 20
order by
	ug.group_name,
	sum(at2.remaining) desc
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
