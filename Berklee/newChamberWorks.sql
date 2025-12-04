--metadb:function newChamberWorks

DROP FUNCTION IF EXISTS newChamberWorks;

CREATE FUNCTION newChamberWorks(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  call_number text,
  barcode text,
  material_type_name text,
  note text,
  title text,
  contributor_name text,
  marc_title text,
  subjects text
  )
AS $$
with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ), 
  btitle as (
    select mt.instance_id, mt.content
    from folio_source_record.marc__t mt 
    where mt.field LIKE '245' and mt.sf LIKE 'b'
    group by mt.instance_id, mt.content),
  subject_field as (
    select mt.instance_id,   STRING_AGG (mt.content, '; ') as subject
    from folio_source_record.marc__t mt 
    where mt.field LIKE '650' and mt.sf LIKE 'a'
    group by mt.instance_id)
select hrt.call_number, ie.barcode, ie.material_type_name, in2.note, it.title, ic2.contributor_name, sb.content as marc_title, sf.subject as subjects
from folio_derived.item_ext ie 
    left join folio_inventory.holdings_record__t hrt ON (hrt.id = ie.holdings_record_id)
    left join folio_inventory.instance__t it ON (it.id = hrt.instance_id)
    left join folio_inventory.instance it2 ON (it2.id = hrt.instance_id)
    left join folio_derived.item_notes in2 ON (ie.item_id = in2.item_id)
    left join inst_contributors ic2 on (it.id = ic2.instance_id)
    left join subject_field sf on (it.id = sf.instance_id)
    left join btitle sb on (it.id = sb.instance_id)
  where in2.note_type_name LIKE 'Collection Code'
  and in2.note LIKE 'SETPT'
and it2.creation_date between start_date and end_date
  order by it.title
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
