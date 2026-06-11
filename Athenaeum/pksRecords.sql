--metadb:function pksRecords

DROP FUNCTION IF EXISTS pksRecords;

CREATE FUNCTION pksRecords(
    shelving_location text DEFAULT '%%'
  )
RETURNS TABLE(
  hrid text,
  index_title text,
  contributor_name text,
  pks_number text,
  effective_location text,
  publisher text,
  date_of_publication text,
  publication_place text, 
  call_number_prefix text,
  call_number text 
  )
AS $$
with
    inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ),
    inst_publishers as (
  select ip.instance_id, ip.publisher, ip.date_of_publication, ip.publication_place
  from folio_derived.instance_publication ip where ip.publication_ordinality='1'
  group by ip.instance_id, ip.publisher, ip.date_of_publication, ip.publication_place)
select 
  ist.hrid,
  ist.index_title,
  cb.contributor_name,
  mt.content as pks_number,
  lt."name" as effective_location,
  pb.publisher,
  pb.date_of_publication,
  pb.publication_place, 
  hd.call_number_prefix,
  hd.call_number
  from
folio_source_record.marc__t mt
left join folio_inventory.instance__t ist on (ist.id = mt.instance_id) 
left join inst_contributors cb on (cb.instance_id = ist.id) 
left join folio_inventory.holdings_record__t hd on (hd.instance_id = ist.id) 
left join folio_inventory.location__t lt on (hd.effective_location_id = lt.id) 
left join inst_publishers pb on (pb.instance_id = ist.id) 
where mt.field = '035' and mt.content ilike '%pks%' and lt."name" ilike shelving_location 
order by mt.content
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
