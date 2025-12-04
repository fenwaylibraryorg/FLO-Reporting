--metadb:function itemLastCheckouts

DROP FUNCTION IF EXISTS itemLastCheckouts;

CREATE FUNCTION itemLastCheckouts(
    item_barcode text DEFAULT '')
RETURNS TABLE(
  loan_date timestamptz,
  username text,
  user_barcode text,
  external_system_id text,
  user_group text,
  loan_action text,
  due_date timestamptz
  )
AS $$
select lt.loan_date, ut.username, ut.barcode as user_barcode, ut.external_system_id, gt."group" as user_group, lt.action as loan_action, lt.due_date 
  from folio_circulation.loan__t__ lt
  left join folio_inventory.item__t it ON (it.id = lt.item_id)
  left join folio_users.users__t ut ON (ut.id = lt.user_id)
  left join folio_users.groups__t gt ON (gt.id = ut.patron_group)
where it.barcode LIKE item_barcode
and lt.action iLIKE 'checkedout%'
  order by lt.loan_date desc
limit 3; 
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
