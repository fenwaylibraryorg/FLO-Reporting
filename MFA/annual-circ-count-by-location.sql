--metadb:function circCount


DROP FUNCTION IF EXISTS circCount;

CREATE FUNCTION circCount(  
  start_date timestamptz DEFAULT '2000-01-01 0:00:00+00',
  end_date timestamptz DEFAULT '2050-01-01 0:00:00+00')
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
and jsonb_extract_path_text(lt.jsonb, 'metadata', 'updatedDate' ) :: timestamp <= end_date + INTERVAL '1 day')
group by rollup(lt2.name)
order by lt2.name nulls last
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
