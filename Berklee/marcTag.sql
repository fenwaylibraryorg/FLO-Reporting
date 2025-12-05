--metadb:function marcTag

DROP FUNCTION IF EXISTS marcTag;

CREATE FUNCTION marcTag(
    marc_tag text DEFAULT '')
RETURNS TABLE(
  campus_name text,
  location_name text,
  barcode text,
  call_number text,
  volume text,
  title text,
  author text,
  tag text,
  hrid text,
  item_status text,
  item_type text
  )
AS $$
select
	distinct ll.campus_name,
	ll.location_name,
	i.jsonb->>'barcode' as "barcode",
	hrt.call_number,
	i.jsonb->>'volume' as "volume",
	it.title,
	ic.contributor_name as "author",
	tag.content as "tag",
	it.hrid,
	i.jsonb->'status'->>'name' as "item_status",
	mtt."name" as "item_type"
from
	folio_inventory.instance__t it
left join (
	select
		distinct instance_id,
		contributor_name
	from
		folio_derived.instance_contributors
	where
		contributor_is_primary = true) ic on
	it.id = ic.instance_id
inner join folio_inventory.holdings_record__t hrt
  on
		it.id = hrt.instance_id
inner join folio_derived.locations_libraries ll on
		hrt.permanent_location_id = ll.location_id
left join folio_inventory.item i on
	hrt.id = i.holdingsrecordid
inner join (
	select
		distinct mt.instance_id,
		mt.content
	from
		folio_source_record.marc__t mt
	where
		mt.field = marc_tag) tag on
	it.id = tag.instance_id
left join folio_inventory.material_type__t mtt on
	i.materialtypeid = mtt.id
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
