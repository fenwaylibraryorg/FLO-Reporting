--metadb:function itemRequest
--7-13-2026 query item-level requests on records w/ multiple copies to cancel and convert to title-level requests

DROP FUNCTION IF EXISTS itemRequest;

CREATE FUNCTION itemRequest()
RETURNS TABLE(
    instance_hrid integer,
    title text,
    request_date timestamptz,
    queue_position integer,
    patron_last_name text,
    patron_last_name text,
    request_link url,
    request_type text,
    total_requests_on_record integer,
    total_items_on_record integer
  )
AS $$
with total_items as (
  select hrt.id, 
  count(*) as items
  from folio_inventory.item__t it2
  join folio_inventory.holdings_record__t hrt on (hrt.id = it2.holdings_record_id)
  group by hrt.id
  ),
  total_requests as (
  select rt.instance_id, count(*) as requests
  from folio_circulation.request__t rt
  where rt.cancelled_date is null
  and rt.status not like '%Closed%'
  and rt.status not like '%Awaiting pickup%'
  and rt.request_level like '%Item%'
  group by rt.instance_id
  )
select distinct  it.hrid as "instance_hrid", 
  it.title,
  rt.request_date,
  rt.position as "queue_position",
  ut.jsonb->'personal'->>'lastName' as "patron_last_name",
  ut.jsonb->'personal'->>'firstName' as "patron_last_name",
  CONCAT('https://ba.folio.indexdata.com/requests/view/', rt.id) as "request_link",
  request_type,
  trt.requests as "total_requests_on_record",
  ti.items as "total_items_on_record"
from folio_inventory.instance__t__ it
inner join folio_inventory.holdings_record__t hrt on (hrt.instance_id = it.id)
left join total_items ti on (ti.id = hrt.id)
left join folio_inventory.item__t it2 on (hrt.id = it2.holdings_record_id)
inner join folio_inventory.location__t lt on (it2.effective_location_id = lt.id)
inner join folio_circulation.request__t rt on (rt.instance_id = it.id)
inner join folio_users.users ut on (ut.id = requester_id)
left join total_requests trt on (trt.instance_id = it.id)
where items > 1 
and requests >= 1
and it2.volume is NULL
and it2.enumeration is NULL
and it2.chronology is NULL
order by hrid, rt.position
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;