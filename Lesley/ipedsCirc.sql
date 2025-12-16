--metadb:function ipedsCirc

DROP FUNCTION IF EXISTS ipedsCirc;

CREATE FUNCTION ipedsCirc(  
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  circ_count integer
  )
AS $$
select
	count(lt.action) as circ_count
from
	folio_circulation.loan__t__ lt
where
	lt.loan_date at TIME zone 'America/New_York' >= start_date 
	and lt.loan_date at TIME zone 'America/New_York' < end_date 
	and lt.action in ('checkedout', 'checkedOutThroughOverride')
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
