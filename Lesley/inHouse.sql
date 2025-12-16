--metadb:function inHouse

DROP FUNCTION IF EXISTS inHouse;

CREATE FUNCTION inHouse(  
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  library_name text,
  circ_count integer
  )
AS $$
select lt3.name as library_name, count(distinct cit.id) as circ_count from folio_circulation.check_in__t__ cit
  left join folio_inventory.item__t it ON (it.id = cit.item_id)
  left join folio_inventory.material_type__t mtt ON (mtt.id = it.material_type_id)
  left join folio_inventory.location__t lt2 ON (it.effective_location_id = lt2.id)
  left join folio_inventory.loclibrary__t lt3 ON (lt3.id = lt2.library_id)
where cit.occurred_date_time AT TIME ZONE 'America/New_York' >= start_date
and cit.occurred_date_time AT TIME ZONE 'America/New_York' < end_date
and cit.item_status_prior_to_check_in = 'Available'
group by lt3.name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
