--metadb:function userCheckoutsByTitle

DROP FUNCTION IF EXISTS userCheckoutsByTitle;

CREATE FUNCTION userCheckoutsByTitle()
RETURNS TABLE
  (last_name text,
  first_name text,
  user_barcode text,
  username text,
  shelving_location text,
  call_number text,
  copy_number text,
  title text,
  author text,
  bib_num text,
  opac_url text,
  barcode text,
  due_date timestamptz,
  user_email text,
  user_group text)
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
  ug.barcode as user_barcode,
  ug.username,
  ie.effective_location_name as shelving_location,
  ie.effective_call_number as call_number,
  ie.copy_number as copy_number,
  ine.title as title,
  c.contributor_name as author,
  ine.instance_hrid as bib_num,
  'https://catalog.berklee.edu/Record/' || ine.instance_hrid as opac_url,
  ie.barcode,
  lt.due_date as due_date,
  ug.user_email as user_email,
  ug.group_name as user_group
  from 
folio_circulation.loan__t lt
left join folio_derived.users_groups ug on (lt.user_id = ug.user_id)
left join folio_derived.item_ext ie on (lt.item_id = ie.item_id)
left join folio_derived.holdings_ext he on (ie.holdings_record_id = he.holdings_id)
left join folio_derived.instance_ext ine on (ine.instance_id = he.instance_id) 
left join inst_contributors c on (c.instance_id = ine.instance_id)
where lt.return_date is null
order by ie.effective_location_name, ie.effective_call_number, ie.copy_number
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
