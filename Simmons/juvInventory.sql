--metadb:function juvInventory

DROP FUNCTION IF EXISTS juvInventory;

CREATE FUNCTION juvInventory()
RETURNS TABLE
  (call_number text,
  copy_number text,
  volume text,
  contributor_name text,
  title text,
  publisher text,
  date_of_publication text,
  barcode text,
  status_name text,
  item_id uuid,
  item_hrid text, 
  instance_id uuid,
  instance_hrid text,
  identifier text
  )
AS $$
with
  inst_contributors as (
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
  inst_pub_dates AS (
    SELECT
        ip.instance_id,
        STRING_AGG(ip.date_of_publication, '|'::TEXT) AS pub_dates,
        STRING_AGG(ip.publisher, '|'::TEXT) AS publisher
    FROM folio_derived.instance_publication ip 
    GROUP BY ip.instance_id
) 
select
  distinct
	he.call_number,
	ite.copy_number,
	ite.volume,
	ic2.contributor_name,
	ie.title,
    ip.publisher,
    substring(ip.pub_dates FROM '[0-9]+') as date_of_publication,
	ite.barcode,
	ite.status_name,
	ite.item_id,
	ite.item_hrid,
	ie.instance_id,
	ie.instance_hrid,
	ii.identifier
from
	folio_derived.instance_ext ie
    left join folio_derived.holdings_ext he on (he.instance_id = ie.instance_id)
    left join folio_derived.item_ext ite on (ite.holdings_record_id = he.holdings_id)
    left join folio_inventory.item__t ii2 on (ii2.holdings_record_id = he.holdings_id)
    left join inst_contributors ic2 on (ie.instance_id = ic2.instance_id)
    left join folio_derived.instance_identifiers ii on (ii.instance_id = ie.instance_id)
    left join inst_pub_dates ip on (ip.instance_id = ie.instance_id)
where
	he.permanent_location_name like 'Children%'
	and
    ii.identifier_type_name = 'OCLC'
	and ite.status_name != 'Withdrawn'
	and ite.status_name != 'In process'
	and ite.status_name != 'Lost and Paid'
	and ite.status_name != 'Aged to Lost'
	and ite.status_name != 'Missing'
order by
	he.call_number
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
