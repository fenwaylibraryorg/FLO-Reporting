--metadb:function yearbooks

DROP FUNCTION IF EXISTS yearbooks;

CREATE FUNCTION yearbooks()
RETURNS TABLE
  (call_number text,
  index_title text,
  instance_hrid text,
  holdings_hrid text,
  permanent_location_name text,
  barcode text 
  )
AS $$
select
	he.call_number,
	ie.index_title,
	ie.instance_hrid,
	he.holdings_hrid,
	he.permanent_location_name,
	ie2.barcode
from
	holdings_ext he
left join instance_ext ie on
	(he.instance_id = ie.instance_id)
left join item_ext ie2 on
	(holdings_id = ie2.holdings_record_id)
where
	ie.instance_hrid = 'p401936'
	or ie.instance_hrid = 'p403810'
	or ie.instance_hrid = 'p402626'
	or ie.instance_hrid = 'p1317749'
	or ie.instance_hrid = 'p402232'
order by
	he.call_number;
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
