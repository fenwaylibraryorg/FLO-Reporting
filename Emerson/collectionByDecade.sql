--metadb:function collectionByDecade

DROP FUNCTION IF EXISTS collectionByDecade;

CREATE FUNCTION collectionByDecade()
RETURNS TABLE
  (location_name text,
  "No_date" integer,
  "pre-1900s" integer,
  "1900s" integer,
  "1910s" integer,
  "1920s" integer,
  "1930s" integer,
  "1940s" integer,
  "1950s" integer,
  "1960s" integer,
  "1970s" integer,
  "1980s" integer,
  "1990s" integer,
  "2000s" integer,
  "2010s" integer,
  "2020s" integer)
AS $$
select sq.name as location_name, "No_date", "Pre-1900s", "1900s", "1910s", "1920s", "1930s", "1940s", "1950s", "1960s", "1970s", "1980s", "1990s", "2000s", "2010s", "2020s"
from (
select lt.name,
  count (*) filter (where ip.date_of_publication is null) as "No_date",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) < '1900') as "Pre-1900s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '190%') as "1900s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '191%') as "1910s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%192%') as "1920s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%193%') as "1930s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%194%') as "1940s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%195%') as "1950s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%196%') as "1960s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%197%') as "1970s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%198%') as "1980s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%199%') as "1990s",
  count (*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%200%') as "2000s",
  count(*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%201%') as "2010s",
  count(*) filter (where left(regexp_replace(ip.date_of_publication, '[^0-9]+', '', 'g'),4) like '%202%')  as "2020s"
  from folio_inventory.holdings_record__t hrt
  left join folio_inventory.location__t lt on (hrt.permanent_location_id = lt.id)
  left join folio_derived.instance_publication ip on (hrt.instance_id = ip.instance_id)
  group by lt.name
) sq
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
