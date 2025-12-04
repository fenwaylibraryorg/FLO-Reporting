--metadb:function withdrawnItems

DROP FUNCTION IF EXISTS withdrawnItems;

CREATE FUNCTION withdrawnItems()
RETURNS TABLE
  (title text,
  contributor_name text,
  call_number text,
  barcode text,
  status_name text,
  status_date text)
AS $$
with inst_contributors as (
select
	ic.instance_id,
	ic.contributor_name
from
	folio_derived.instance_contributors ic
where
	ic.contributor_is_primary = 'TRUE'
group by
	ic.instance_id,
	ic.contributor_name
)
select
	it.title,
	ic2.contributor_name,
	hrt.call_number,
	it2.barcode,
	jsonb_extract_path_text(i.jsonb,
	'status',
	'name') as status_name,
	jsonb_extract_path_text(i.jsonb,
	'status',
	'date') as status_date
from
	folio_inventory.item i
left join folio_inventory.item__t it2 on
	(i.id = it2.id)
left join folio_inventory.holdings_record__t hrt on
	(i.holdingsrecordid = hrt.id)
left join folio_inventory.instance__t it on
	(it.id = hrt.instance_id)
left join inst_contributors ic2 on
	(it.id = ic2.instance_id)
where
	jsonb_extract_path_text(i.jsonb,
	'status',
	'name') like 'Withdrawn'
order by
	it.title asc
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
