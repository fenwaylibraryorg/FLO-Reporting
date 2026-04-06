--metadb:function finesFees

DROP FUNCTION IF EXISTS finesFees;

CREATE FUNCTION finesFees()
RETURNS TABLE(
  last_name text,
  first_name text, 
  patron_group text,
  email text,
  patron_barcode text,
  fee_fine_type text,
  account_balance integer,
  item_barcode text
  )
AS $$
select 
ug.user_last_name as last_name,
ug.user_first_name as first_name,
ug.group_name as patron_group,
ug.user_email as email,
ug.barcode as patron_barcode,
faa.fee_fine_type,
faa.account_balance::money,
at2.barcode as item_barcode
from
folio_derived.users_groups ug
left join folio_derived.feesfines_accounts_actions faa on (ug.user_id = faa.user_id)
left join folio_feesfines.accounts__t at2 on (faa.account_id = at2.id) 
where at2.remaining > 0
order by ug.user_last_name, ug.user_first_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
