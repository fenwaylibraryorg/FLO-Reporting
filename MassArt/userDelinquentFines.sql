--metadb:function userDelinquentFines

DROP FUNCTION IF EXISTS userDelinquentFines;

CREATE FUNCTION userDelinquentFines()
RETURNS TABLE
  (last_name text,
  first_name text,
  user_address text,
  username text,
  user_group text,
  fine_date timestamptz,
  balance_owed text
 )
AS $$
select 
ug.user_last_name as last_name,
ug.user_first_name as first_name,
ua.address_line_1 as user_address,
ug.username as username,  
ug.group_name as user_group,
faa.fine_date as fine_date,
concat('$', sum(faa.account_balance)) as balance_owed
from
folio_derived.users_groups ug
left join folio_derived.feesfines_accounts_actions faa on (ug.user_id = faa.user_id)
left join folio_derived.users_addresses ua on (ua.user_id = ug.user_id) 
where ug.group_name in ('Student', 'Cont. Ed. Student', 'Graduate Student')
group by ug.group_name, ug.user_last_name, ug.user_first_name, ua.address_line_1, ug.username, faa.fine_date
having sum(faa.account_balance) >= 10
order by ug.group_name, sum(faa.account_balance), ug.user_last_name desc
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
