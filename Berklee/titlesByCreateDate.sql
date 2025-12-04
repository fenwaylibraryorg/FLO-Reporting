--metadb:function titlesByCreateDate

DROP FUNCTION IF EXISTS titlesByCreateDate;

CREATE FUNCTION titlesByCreateDate(  
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (instance_id uuid,
  material_type_name text,
  title text,
  contributor_name text,
  publisher text,
  date_of_publication text,
  barcode text,
  call_number text
  )
AS $$
with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ),
  inst_publishers as (
  select ip.instance_id, ip.publisher, ip.date_of_publication
  from folio_derived.instance_publication ip where ip.publication_ordinality='1'
  group by ip.instance_id, ip.publisher, ip.date_of_publication)
select 
  it.id as instance_id, 
  ie.material_type_name, 
  it.title, 
  ic2.contributor_name, 
  ip2.publisher, 
  ip2.date_of_publication,
  ie.barcode, 
  hrt.call_number
  from folio_derived.item_ext ie
  left join folio_inventory.holdings_record__t hrt ON (hrt.id = ie.holdings_record_id)
  left join folio_inventory.instance__t it ON (it.id = hrt.instance_id)
  left join inst_contributors ic2 on (it.id = ic2.instance_id)
  left join inst_publishers ip2 on (it.id = ip2.instance_id)
where ie.created_date between start_date and end_date
 order by ie.material_type_name, it.title
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
