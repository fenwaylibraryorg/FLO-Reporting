--metadb:function teachingMedia

DROP FUNCTION IF EXISTS teachingMedia;

CREATE FUNCTION teachingMedia()
RETURNS TABLE
  (permanent_location_name text,
  call_number text,
  material_type_name text,
  index_title text,
  contributor_name text,
  barcode text,
  temporary_location_name text,
  holdings_hrid text,
  item_hrid text,
  effective_shelving_order text,
  status_name text,
  loan_date timestamptz
  )
AS $$
with 
  inst_contributors AS (
  select ic.instance_id, ic.contributor_name
  from 
  folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  )
select distinct
  hrt.permanent_location_name,
  hrt.call_number, 
  ie.material_type_name, 
  i.index_title,
  ic2.contributor_name, 
  ie.barcode, 
  ie.temporary_location_name, 
  hrt.holdings_hrid, 
  ie.item_hrid, 
  i2.effective_shelving_order, 
  ie.status_name,
  li.loan_date
  from folio_derived.item_ext ie
  left join folio_inventory.item__t i2 on (ie.item_id = i2.id) 
  left join folio_derived.holdings_ext hrt on (hrt.holdings_id = ie.holdings_record_id)
  left join folio_inventory.instance__t i on (hrt.instance_id = i.id)
  left join inst_contributors ic2 on (i.id = ic2.instance_id) 
  left join (select distinct item_id,loan_date from folio_derived.loans_items where item_status!='Available') li on ie.item_id = li.item_id
  where (hrt.permanent_location_name = 'Teaching Media Collection - Ask at Service Desk' OR hrt.permanent_location_name = 'Teaching Media Collection (storage) - Ask at Service Desk') 
  order by hrt.permanent_location_name, ie.material_type_name, i2.effective_shelving_order, i.index_title 
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
