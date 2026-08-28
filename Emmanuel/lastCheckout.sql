--metadb:function lastCheckout

DROP FUNCTION IF EXISTS lastCheckout;

CREATE FUNCTION lastCheckout(
    start_cn_range text DEFAULT '',
    end_cn_range text DEFAULT '')
RETURNS TABLE(
  effective_call_number text,
  title text,
  volume text,
  barcode text,
  pub_date text,
  last_loan_date text
  )
AS $$
with   
  inst_publishers as (
  select ip.instance_id, ip.publisher, substring(ip.date_of_publication FROM '[0-9]+') as pub_date
  from folio_derived.instance_publication ip where ip.publication_ordinality='1'
  group by ip.instance_id, ip.publisher, (substring(ip.date_of_publication FROM '[0-9]+'))),
  last_loan as (
  select it.id, max(lt.loan_date) as last_loan_date
  from folio_circulation.loan__t__ lt
  left join folio_inventory.item__t it ON (it.id = lt.item_id)
  where lt.action iLIKE 'checkedout%' /*includes checked out or checked out through override*/
  group by it.id)
select
  ie.effective_call_number,
  it.title, 
  ie.volume,
  ie.barcode, 
  ip.pub_date,
  ll.last_loan_date::date::text
from folio_inventory.instance__t it
left join inst_publishers ip on (ip.instance_id = it.id)
left join folio_derived.holdings_ext he on (it.id = he.instance_id)
left join folio_derived.item_ext ie on (ie.holdings_record_id = he.holdings_id)
left join folio_inventory.item__t it2 on (ie.item_id = it2.id) 
left join last_loan ll on (ll.id = ie.item_id)
where ie.effective_call_number between start_cn_range and end_cn_range
order by it2.effective_shelving_order, ie.barcode
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
