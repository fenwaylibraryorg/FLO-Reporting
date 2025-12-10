--metadb:function circByHour

DROP FUNCTION IF EXISTS circByHour;

CREATE FUNCTION circByHour()
RETURNS TABLE
  (circ_day text,
  circ_hour text,
  material_type text,
  circ_count integer)
AS $$
select
	TO_CHAR(lt.loan_date,
	'DY') as circ_day,
	to_char(lt.loan_date,
	'FMHH12 am') as circ_hour,
	mtt.name as material_type,
	count(distinct lt.id) as circ_count
from
	folio_circulation.loan__t lt /*current loan table*/
left join folio_inventory.item__t it on
	(it.id = lt.item_id)
left join folio_inventory.material_type__t mtt on
	(mtt.id = it.material_type_id)
group by
	circ_day,
	circ_hour,
	material_type,
	extract(DOW from loan_date),
	extract(hour from loan_date)
order by
	extract(DOW from loan_date),
	extract(hour from loan_date),
	mtt.name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
