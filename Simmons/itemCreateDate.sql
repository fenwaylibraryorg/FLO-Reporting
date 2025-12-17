--metadb:function itemCreateDate

DROP FUNCTION IF EXISTS itemCreateDate;

CREATE FUNCTION itemCreateDate(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (item_count integer)
AS $$
select count(ii.item_id) as item_count
from 
folio_derived.item_ext ii 
where ii.created_date between start_date and end_date
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
