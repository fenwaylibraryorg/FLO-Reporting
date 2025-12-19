--metadb:function circMainUsage

DROP FUNCTION IF EXISTS circMainUsage;

CREATE FUNCTION circMainUsage(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (num_of_checkouts integer,
  count_of_items integer 
  )
AS $$
select counts as num_of_checkouts, count(1) as count_of_items
  from 
  (select it.id, count(distinct lt.id) as counts from folio_inventory.item__t__ it
  left join folio_inventory.holdings_record__t__ hrt ON (hrt.id = it.holdings_record_id)
  left join folio_inventory.instance__t__ it2 ON (it2.id = hrt.instance_id)
  left join folio_circulation.loan__t__ lt ON (it.id = lt.item_id)
  left join folio_inventory.location__t__ lt2 ON (lt2.id = hrt.permanent_location_id)
  left join folio_inventory.material_type__t__ mtt ON (it.material_type_id = mtt.id)
where (lt.loan_date between  start_date and end_date) /*enter the start and end dates*/
  and (lt2.name LIKE 'Main Stacks')
  and (mtt.name LIKE 'Book' or mtt.name LIKE 'Juvenile Books')
  group by it.id)
group by counts
order by counts
/*this report shows distribution by count of number of loans. can revisit after go-live*/
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
