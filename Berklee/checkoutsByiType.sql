--metadb:function checkoutsByiType

DROP FUNCTION IF EXISTS checkoutsByiType;

CREATE FUNCTION checkoutsByiType(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (material_type text,
  checkouts integer)
AS $$
select
	coalesce(mtt.name,
	'Total Checkouts') as material_type,
	count(distinct lt.id) as checkouts
from
	folio_circulation.loan__t__ lt
join folio_inventory.item__t__ it on
	(lt.item_id = it.id)
join folio_inventory.material_type__t__ mtt on
	(it.material_type_id = mtt.id)
where
	lt.loan_date between start_date and end_date 
	and (lt.action = 'checkedout'
		or lt.action = 'checkedOutThroughOverride')
group by
	rollup(mtt.name)
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
