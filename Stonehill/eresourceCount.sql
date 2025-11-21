--metadb:function eresourceCount

DROP FUNCTION IF EXISTS eresourceCount;

CREATE FUNCTION eresourceCount()
RETURNS TABLE
  (instance_count integer)
AS $$
select count(distinct iea.instance_hrid) as instance_count
from
folio_derived.instance_electronic_access iea
where iea.instance_hrid not in (select instance_hrid from folio_derived.instance_electronic_access where public_note like '%DDA%')
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
