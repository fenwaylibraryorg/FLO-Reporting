--metadb:function itemRequest


DROP FUNCTION IF EXISTS circCount;

CREATE FUNCTION circCount(  
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  shelving_location text,
  circ_count integer
  )
AS $$
select lt2.name as "shelving_location", count(lt.jsonb->'action') as "circ_count"
from folio_circulation.loan__ lt
join folio_inventory.location__t lt2 ON ((lt.jsonb->>'itemEffectiveLocationIdAtCheckOut') :: uuid = lt2.id)
where lt.jsonb->>'action' in ('checkedout','renewed','checkedOutThroughOverride', 'renewedThroughOverride')
and (jsonb_extract_path_text(lt.jsonb, 'metadata', 'updatedDate' ) :: timestamp >= start_date 
and jsonb_extract_path_text(lt.jsonb, 'metadata', 'updatedDate' ) :: timestamp <= end_date)
group by rollup(lt2.name)
order by lt2.name nulls last
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;