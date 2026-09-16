--metadb:function agedLost

DROP FUNCTION IF EXISTS agedLost;

CREATE FUNCTION agedLost()
RETURNS TABLE(
    title text,
    contributor_name text,
    publisher text,
    date_of_publication text,
    effective_call_number text,
    perm_location text,
    effective_location text,
    material_type text,
    item_barcode text,
    instance text,
    user_last_name text,
    user_first_name text,
    user_barcode text,
    status_name text,
    loan_date text,
    due_date text
  )
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
	it.title,
	ic2.contributor_name,
	ip2.publisher,
	ip2.date_of_publication,
	jsonb_extract_path_text(i.jsonb,
	'effectiveCallNumberComponents',
	'callNumber') as effective_call_number,
	lt.name as perm_location,
	iloc.name as effective_location, 
	mat.name as material_type,
	ie.barcode as item_barcode,
	it.hrid as instance,
	jsonb_extract_path_text(ug.jsonb,
	'personal',
	'lastName') as user_last_name,
	jsonb_extract_path_text(ug.jsonb,
	'personal',
	'firstName') as user_first_name,
	jsonb_extract_path_text(ug.jsonb,
	'barcode') as user_barcode,
	jsonb_extract_path_text(i.jsonb,
	'status',
	'name') as status_name,
	lt2.loan_date::date::text,
	lt2.due_date::date::text
from
	folio_inventory.item__t ie
left join folio_inventory.item i 
    on
	(ie.id = i.id)
left join folio_inventory.holdings_record__t hrt on
	(ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t lt on
	(hrt.permanent_location_id = lt.id)
left join folio_inventory.location__t iloc on
	(ie.effective_location_id = iloc.id)
left join folio_inventory.material_type__t mat on
	(ie.material_type_id = mat.id)
left join folio_inventory.instance__t it on
	(hrt.instance_id = it.id)
left join inst_contributors ic2 on
	(it.id = ic2.instance_id)
left join inst_publishers ip2 on
	(it.id = ip2.instance_id)
left join folio_circulation.loan__t lt2 on
	(lt2.item_id = ie.id)
left join folio_circulation.loan lm on
	(lm.id = lt2.id)
left join folio_users.users ug on
	(ug.id = lt2.user_id)
where
	jsonb_extract_path_text(lm.jsonb,
	'status',
	'name') = 'Open'
	and jsonb_extract_path_text(i.jsonb,
	'status',
	'name') like 'Aged to lost'
order by
	lt.name,
	iloc.name,
	mat.name,
	ie.effective_shelving_order
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
