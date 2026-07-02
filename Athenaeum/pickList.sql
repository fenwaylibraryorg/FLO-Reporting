--metadb:function pickList

DROP FUNCTION IF EXISTS pickList;

CREATE FUNCTION pickList(    
  start_page_date date DEFAULT '2000-01-01',
  end__page_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (request_date date,
  user_last_name text,
  user_first_name text,
  user_middle_name text, 
  page_expires date,
  title text,
  contributor_name text,
  effective_shelving_location text,
  call_number text,
  barcode text,
  volume text,
  request_level text,
  patron_comments text)
AS $$
with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  )
select 
  (request_date AT TIME ZONE 'America/New_York')::date AS request_date,
  jsonb_extract_path_text(ut.jsonb, 'personal', 'lastName') AS user_last_name,
  jsonb_extract_path_text(ut.jsonb, 'personal', 'firstName') AS user_first_name,
  jsonb_extract_path_text(ut.jsonb, 'personal', 'middleName') AS user_middle_name,
  (rt.request_expiration_date AT TIME ZONE 'America/New_York')::date AS page_expires,
  it.title,
  ic2.contributor_name,
  lt.name as effective_shelving_location,
  hrt.call_number,
  it2.barcode,
  it2.volume,
  request_level,
  rt.patron_comments
from 
folio_circulation.request__t rt
left join folio_users.users ut on (rt.requester_id = ut.id)
left join folio_inventory.instance__t it on (rt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join folio_inventory.item__t it2 on (rt.item_id = it2.id)
inner join folio_inventory.item i on (it2.id = i.id)
left join folio_inventory.holdings_record__t hrt on (rt.holdings_record_id = hrt.id) 
left join folio_inventory.location__t lt on (it2.effective_location_id = lt.id) 
where rt.request_type = 'Page' and rt.status = 'Open - Not yet filled' and (request_date AT TIME ZONE 'America/New_York')::date Between start_page_date and end_page_date
order by lt.name, i.jsonb->>'effectiveShelvingOrder' asc
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
