--metadb:function displayCheckedOut

DROP FUNCTION IF EXISTS displayCheckedOut;

CREATE FUNCTION displayCheckedOut(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (count_of_charges integer,
  material_type_name text,
  index_title text,
  contributor_name text,
  call_number text,
  barcode text,
  temporary_location_name text,
  permanent_location_name text,
  holdings_hrid text,
  item_hrid text,
  effective_shelving_order text,
  loan_date timestamptz,
  due_date timestamptz,
  loan_action text 
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
  count (lt.item_id) as Count_of_charges,
  ie.material_type_name, 
  i.index_title,
  ic2.contributor_name, 
  hrt.call_number, 
  ie.barcode, 
  ie.temporary_location_name, 
  hrt.permanent_location_name, 
  hrt.holdings_hrid, 
  ie.item_hrid, 
  i2.effective_shelving_order,
  lt.loan_date,
  lt.due_date,
  lt.action as loan_action
  from
  folio_derived.item_ext ie
  left join folio_inventory.item__t i2 on (ie.item_id = i2.id) 
  left join folio_derived.holdings_ext hrt on (hrt.holdings_id = ie.holdings_record_id)
  left join folio_inventory.instance__t i on (hrt.instance_id = i.id)
  left join inst_contributors ic2 on (i.id = ic2.instance_id)
  left join folio_circulation.loan__t__ lt on (i2.id = lt.item_id) /*all loans, current or not */
  where (ie.temporary_location_name = 'Display' OR hrt.permanent_location_name = 'Display') 
  and lt.loan_date BETWEEN start_date and end_date /*enter dates here*/  
  group by lt.item_id, ie.material_type_name, 
  i.index_title,
  ic2.contributor_name, 
  hrt.call_number, 
  ie.barcode, 
  ie.temporary_location_name, 
  hrt.permanent_location_name, 
  hrt.holdings_hrid, 
  ie.item_hrid, 
  i2.effective_shelving_order,
  lt.loan_date,
  lt.due_date,
  lt.action
  order by ie.material_type_name, i.index_title, i2.effective_shelving_order
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
