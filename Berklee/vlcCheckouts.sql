--metadb:function vlcCheckouts

DROP FUNCTION IF EXISTS vlcCheckouts;

CREATE FUNCTION vlcCheckouts(
  bcm_group text DEFAULT 'Student',
  orientation_date date DEFAULT '2000-01-01')
RETURNS TABLE(
  last_name text,
  first_name text,
  patron_barcode text,
  username text,
  library_name text,
  shelving_location text,
  call_number text,
  copy_number text,
  title text,
  author text,
  bib_number text, 
  opac_link text,
  item_barcode text,
  due_date timestamptz,
  user_email text,
  user_group text
  )
AS $$
with 
  inst_contributors AS (
  select ic.instance_id, ic.contributor_name
  from 
  folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  )
select 
  ug.user_last_name as last_name,
  ug.user_first_name as first_name,
  ug.barcode as patron_barcode,
  ug.username,
  lt3.name as library_name,
  ie.effective_location_name as shelving_location,
  ie.effective_call_number as call_number,
  ie.copy_number as copy_number,
  ine.title as title,
  c.contributor_name as author,
  ine.instance_hrid as bib_number,
  'https://catalog.berklee.edu/Record/' || ine.instance_hrid as opac_link,
  ie.barcode as item_barcode,
  lt.due_date,
  ug.user_email,
  ug.group_name
from folio_circulation.loan__t lt
left join folio_derived.users_groups ug on (lt.user_id = ug.user_id)
left join folio_derived.item_ext ie on (lt.item_id = ie.item_id)
left join folio_derived.holdings_ext he on (ie.holdings_record_id = he.holdings_id)
left join folio_derived.instance_ext ine on (ine.instance_id = he.instance_id) 
left join inst_contributors c on (c.instance_id = ine.instance_id)
join folio_inventory.item__t it ON (it.id = lt.item_id)
left join folio_inventory.location__t lt2 ON (it.effective_location_id = lt2.id)
left join folio_inventory.loclibrary__t lt3 ON (lt3.id = lt2.library_id)
Where
  lt.return_date is null
  and lt.due_date > orientation_date
  and lt3.name in ('Valencia Library') 
  and ug.group_name = bcm_group
  order by ie.effective_location_name, ie.effective_call_number, ie.copy_number
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
