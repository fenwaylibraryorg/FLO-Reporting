--metadb:function fundNameYear

DROP FUNCTION IF EXISTS fundNameYear;

CREATE FUNCTION fundNameYear(
    fnd_name text DEFAULT '',
    fnd_year text DEFAULT ''
  )
RETURNS TABLE(
  hrid text,
  index_title text,
  contributor_name text,
  fund_name text,
  fiscal_year text
  )
AS $$
with fund_name as (
  select hn.holding_id, hn.note, hn.note_type_name
  from folio_derived.holdings_notes hn 
  where hn.note_type_name = 'Fund Name' 
  ),
fund_year as (
  select hn.holding_id, hn.note, hn.note_type_name
  from folio_derived.holdings_notes hn 
  where hn.note_type_name = 'Fiscal Year' 
  ),
  inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  )
select 
  ist.hrid,
  ist.index_title,
  cb.contributor_name, 
  fn.note as fund_name,
  fy.note as fiscal_year
from 
folio_inventory.instance__t ist
left join folio_inventory.holdings_record__t hd on (ist.id = hd.instance_id) 
left join inst_contributors cb on (cb.instance_id = ist.id) 
inner join fund_name fn on (fn.holding_id = hd.id) 
inner join fund_year fy on (fy.holding_id = hd.id) 
where fn.note = fnd_name and fy.note = fnd_year 
order by fy.note, fn.note
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
