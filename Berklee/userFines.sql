--metadb:function userFines

DROP FUNCTION IF EXISTS userFines;

CREATE FUNCTION userFines()
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
ug.group_name as user_group,
ug.user_last_name as last_name,
ug.user_first_name as first_name,
ug.user_email as user_email, 
ug.username,  
ug.barcode as user_barcode,
concat('$', sum(faa.account_balance)) as balance
from
folio_derived.users_groups ug
left join folio_derived.feesfines_accounts_actions faa on (ug.user_id = faa.user_id)
group by ug.group_name, ug.user_last_name, ug.user_first_name, ug.user_email, ug.username, ug.barcode
having sum(faa.account_balance) > 0
order by ug.group_name, ug.user_last_name, ug.user_first_name, sum(faa.account_balance)
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
