--metadb:function userDelinquentOverdues

DROP FUNCTION IF EXISTS userDelinquentOverdues;

CREATE FUNCTION userDelinquentOverdues()
RETURNS TABLE
  (user_last_name text,
  user_first_name text,
  username text,
  group_name text,
  loan_due_date timestamptz,
 )
AS $$
select 
  ug.user_last_name,
  ug.user_first_name, 
  ug.username,
  ug.group_name,
  li.loan_due_date::date
  from
  folio_derived.loans_items li
  left join folio_derived.users_groups ug on (li.user_id = ug.user_id) 
  left join folio_inventory.item__t it on (it.id = li.item_id)
  left join folio_inventory.holdings_record__t hrt on (hrt.id = it.holdings_record_id)
  left join folio_inventory.instance__t it2 on (it2.id = hrt.instance_id)
  where li.loan_return_date is null and li.loan_due_date < CURRENT_DATE and ug.group_name in ('Student', 'Cont. Ed. Student', 'Graduate Student')
  order by li.loan_due_date asc
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
