--metadb:function proquestCallNo

DROP FUNCTION IF EXISTS proquestCallNo;

CREATE FUNCTION proquestCallNo()
RETURNS TABLE
  (holdings_hrid text,
  call_number text,
  uri text,
  user_full_name text
  )
AS $$
select
	he.holdings_hrid,
	he.call_number,
	hea.uri,
	CONCAT(ug.user_first_name,
	' ',
	ug.user_last_name) as user_full_name
from
	folio_derived.holdings_ext he
left join folio_derived.holdings_electronic_access hea on
	(he.holdings_id = hea.holdings_id)
left join folio_derived.users_groups ug on
	(he.updated_by_user_id::uuid = ug.user_id)
where
	he.permanent_location_name like 'E-%'
	and (he.call_number like 'ProQuest%'
		or he.call_number like 'Ebook%')
order by
	user_full_name,
	he.call_number
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
