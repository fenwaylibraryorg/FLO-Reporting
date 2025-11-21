--metadb:function circByItemType

DROP FUNCTION IF EXISTS circByItemType;

CREATE FUNCTION circByItemType(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (material_type text,
  circ_count integer)
AS $$
select coalesce(mtt.name, 'Total Circs') as material_type, count(lt.action) as circ_count from folio_circulation.loan__t__ lt
  left join folio_inventory.item__t it ON (it.id = lt.item_id)
  left join folio_inventory.material_type__t mtt ON (mtt.id = it.material_type_id)
where start_date <= lt.loan_date AND lt.loan_date <= end_date
  and lt.action in ('checkedout','renewed','renewedThroughOverride','checkedOutThroughOverride','dueDateChanged')
group by ROLLUP (mtt.name)
order by mtt.name NULLS last
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
