--metadb:function hourlyCirc

DROP FUNCTION IF EXISTS hourlyCirc;

CREATE FUNCTION hourlyCirc(  
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  library_name text,
  circ_day text,
  circ_hour text,
  circ_count integer
  )
AS $$
select lt3.name as library_name,
  TO_CHAR(lt.loan_date AT TIME ZONE 'America/New_York','DY') as circ_day,
  TO_CHAR(lt.loan_date AT TIME ZONE 'America/New_York', 'FMHH12 am') as circ_hour,
	count(distinct lt.id) as circ_count
from folio_circulation.loan__t__ lt
left join folio_inventory.item__t it on (it.id = lt.item_id)
left join folio_inventory.material_type__t mtt on (mtt.id = it.material_type_id)
left join folio_inventory.location__t lt2 on (it.effective_location_id = lt2.id)
left join folio_inventory.loclibrary__t lt3 on (lt3.id = lt2.library_id)
left join folio_users.groups__t__ gt on (lt.patron_group_id_at_checkout = gt.id)
where (lt.loan_date AT TIME ZONE 'America/New_York' >= start_date and lt.loan_date AT TIME ZONE 'America/New_York' < end_date )
and (lt.action = 'checkedout' or lt.action = 'checkedOutThroughOverride')
and gt.group not in ('ComCat', 'ReShare Library')
and mtt.name not in ('Comcat Item', 'ReShare Item')
and lt3.name = 'Sherrill Library'
group by circ_day, circ_hour, lt3.name, extract(DOW from loan_date AT TIME ZONE 'America/New_York'), extract(hour from loan_date AT TIME ZONE 'America/New_York')
order by extract(DOW from loan_date AT TIME ZONE 'America/New_York'), extract(hour from loan_date AT TIME ZONE 'America/New_York')
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
