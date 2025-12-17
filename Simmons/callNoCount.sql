--metadb:function callNoCount

DROP FUNCTION IF EXISTS callNoCount;

CREATE FUNCTION callNoCount(
    start_cn_range text DEFAULT '',
    end_cn_range text DEFAULT '')
RETURNS TABLE(
item_count integer
  )
AS $$
select
	count(it2.id) as item_count
from
	folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on
	(hrt.instance_id = it.id)
left join folio_inventory.item__t it2 on
	(it2.holdings_record_id = hrt.id)
where
	hrt.call_number between start_cn_range and end_cn_range
	or it2.item_level_call_number between start_cn_range and end_cn_range
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
