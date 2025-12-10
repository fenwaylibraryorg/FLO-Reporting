--metadb:function itemsByPubDate

DROP FUNCTION IF EXISTS itemsByPubDate;

CREATE FUNCTION itemsByPubDate()
RETURNS TABLE
  (begin_pub text,
  item_count integer)
AS $$
select
	rtrim(substring(ip.date_of_publication
from
	'[\d]+')) as Begin_pub,
	count(distinct ie.item_id) as item_count
from
	folio_derived.instance_publication ip
left join folio_inventory.instance__t it on
	(it.id = ip.instance_id)
left join folio_inventory.holdings_record__t hrt on
	(it.id = hrt.instance_id)
left join folio_derived.item_ext ie on
	(hrt.id = ie.holdings_record_id)
where
	ie.material_type_name like 'Book'
	and ie.effective_location_name like 'Main Stacks'
	and ip.publication_role like 'Publication'
group by
	begin_pub
order by
	begin_pub
/*Main stacks = location, book = item type, takes beginning pub date if there is a range 
This will take publication dates only */
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
