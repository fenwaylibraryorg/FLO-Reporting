--metadb:function newBooks

DROP FUNCTION IF EXISTS newBooks;

CREATE FUNCTION newBooks()
RETURNS TABLE(
  hrid text,
  barcode text,
  title text,
  effective_shelving_location text,
  call_number text,
  contributor_name text,
  publisher text,
  date_of_publication text,
  publication_place text,
  vufind_link text,
  call_number_sort text 
  )
AS $$
 with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  )
select distinct it.hrid, 
  it2.barcode,
  it.title,
  lt.name as effective_shelving_location,
  hrt.call_number, 
  ic2.contributor_name,
  ip.publisher,
  ip.date_of_publication,
  ip.publication_place,
  CONCAT('https://catalog.bostonathenaeum.org/Record/', it.hrid) as vufind_link,
  i.jsonb->>'effectiveShelvingOrder' as call_number_sort
from folio_inventory.instance__t__ it
inner join folio_inventory.holdings_record__t hrt on (hrt.instance_id = it.id)
inner join folio_inventory.item__t it2 on (it2.holdings_record_id = hrt.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
inner join folio_derived.instance_publication ip on (ip.instance_id = it.id)
inner join folio_inventory.item i on (it2.id = i.id)
inner join folio_inventory.location__t lt on (i.effectiveLocationId = lt.id)
where lt.name in ('New Book (14 Days)', 'New Book (28 Days)', 'New Books')
and ip.publication_ordinality = '1'
order by lt.name, i.jsonb->>'effectiveShelvingOrder' asc
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
