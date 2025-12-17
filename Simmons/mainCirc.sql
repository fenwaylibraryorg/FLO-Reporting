--metadb:function mainCirc

DROP FUNCTION IF EXISTS mainCirc;

CREATE FUNCTION mainCirc(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (loan_count integer,
  barcode text,
  title text,
  contributor_name text,
  date_of_publication text,
  call_number text,
  material_type_name text,
  item_effective_location_name_at_check_out text)
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
  ),
  inst_publishers as (
select
	ip.instance_id,
	ip.publisher,
	ip.date_of_publication
from
	folio_derived.instance_publication ip
where
	ip.publication_ordinality = '1'
group by
	ip.instance_id,
	ip.publisher,
	ip.date_of_publication)
select
	count (li.loan_id) as loan_count,
	li.barcode,
	ie.title,
	ic2.contributor_name,
	ip2.date_of_publication,
	he.call_number,
	li.material_type_name,
	li.item_effective_location_name_at_check_out
from 
	folio_derived.loans_items li
left join folio_derived.holdings_ext he on
	(he.holdings_id = li.holdings_record_id)
left join folio_derived.instance_ext ie on
	(ie.instance_id = he.instance_id)
left join folio_inventory.item__t ie2 on
	(li.item_id = ie2.id)
left join inst_contributors ic2 on
	(ie.instance_id = ic2.instance_id)
left join inst_publishers ip2 on
	(ie.instance_id = ip2.instance_id)
where 
	li.loan_date between start_date and end_date
	and li.item_effective_location_name_at_check_out like '%Main%'
	and li.barcode is not null
group by
	li.barcode,
	ie.title,
	ic2.contributor_name,
	ip2.date_of_publication,
	he.call_number,
	li.material_type_name,
	li.item_effective_location_name_at_check_out,
	ie2.effective_shelving_order
order by
	ie2.effective_shelving_order
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
