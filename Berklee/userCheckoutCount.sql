--metadb:function userCheckoutCount

DROP FUNCTION IF EXISTS userCheckoutCount;

CREATE FUNCTION userCheckoutCount()
RETURNS TABLE
  (last_name text,
  first_name text,
  user_barcode text,
  username text,
  user_email text,
  user_group text,
  service_point text,
  loan_count integer)
AS $$
select
	ug.user_last_name as last_name,
	ug.user_first_name as first_name,
	ug.barcode as user_barcode,
	ug.username,
	ug.user_email as user_email,
	ug.group_name as user_group,
	spt."name" as service_point,
  count(lt.id) as loan_count
from
	folio_circulation.loan__t lt
left join folio_derived.users_groups ug on
	(lt.user_id = ug.user_id)
left join folio_inventory.service_point__t spt on
	(lt.checkout_service_point_id = spt.id)
where
	lt.return_date is null
group by ug.user_last_name, ug.user_first_name, ug.barcode, ug.username, ug.user_email, ug.group_name, spt."name"
order by
	ug.group_name,
	ug.user_email
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
