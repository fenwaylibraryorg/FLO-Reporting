--metadb:function loanTypeByLoc

DROP FUNCTION IF EXISTS loanTypeByLoc;

CREATE FUNCTION loanTypeByLoc()
RETURNS TABLE
  (location_name text,
  permanent_loan_type_name text,
  item_count integer
  )
AS $$
select
	lt.name as location_name,
	ie.permanent_loan_type_name,
	count(ie.permanent_loan_type_name) as item_count
from
	folio_derived.item_ext ie
left join folio_inventory.holdings_record__t hrt on
	(ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t__ lt on
	(hrt.permanent_location_id = lt.id)
left join folio_inventory.loclibrary__t__ lib on
	(lt.library_id = lib.id)
where
	permanent_loan_type_name != 'Can circulate'
group by
	lt.name,
	ie.permanent_loan_type_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
