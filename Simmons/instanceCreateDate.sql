--metadb:function instanceCreateDate

DROP FUNCTION IF EXISTS instanceCreateDate;

CREATE FUNCTION instanceCreateDate(
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01'
)
RETURNS TABLE
  (instance_count integer
  )
AS $$
select count(ie.instance_id) as instance_count
from 
folio_derived.instance_ext ie
where ie.record_created_date between start_date and end_date
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
