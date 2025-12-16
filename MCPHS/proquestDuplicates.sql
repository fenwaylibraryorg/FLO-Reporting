--metadb:function proquestDuplicates

DROP FUNCTION IF EXISTS proquestDuplicates;

CREATE FUNCTION proquestDuplicates()
RETURNS TABLE
  (uri text,
  holdings_hrid text,
  discovery_suppress text
  )
AS $$
select
	distinct dupe.uri,
	hea2.holdings_hrid, he.discovery_suppress
from
	folio_derived.holdings_ext he inner join
 folio_derived.holdings_electronic_access hea2 on he.holdings_id=hea2.holdings_id
inner join 
(
	select
		distinct hea.uri,
		count(distinct hea.holdings_id)
	from
		folio_derived.holdings_ext he
	inner join folio_derived.holdings_electronic_access hea on
		he.holdings_id = hea.holdings_id
    /*where he.discovery_suppress IS NULL*/
	group by
		hea.uri
	having
		count(distinct hea.holdings_id) > 1) dupe on
	hea2.uri = dupe.uri
  where hea2.uri like '%ebookcentral%'
  order by dupe.uri, he.discovery_suppress
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
