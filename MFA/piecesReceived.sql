--metadb:function piecesReceived

DROP FUNCTION IF EXISTS piecesReceived;

CREATE FUNCTION piecesReceived()
RETURNS TABLE
  (month_received integer,
  year_received integer,
  total_pieces_received integer 
  )
AS $$
select
  extract(month from pt.received_date) as month_received,
  extract(year from pt.received_date) as year_received,
  count(distinct pt.id) as total_pieces_received
from 
folio_orders.pieces__t__ pt
where pt.received_date is not null
group by extract(month from pt.received_date), extract(year from pt.received_date) 
order by extract(year from pt.received_date), extract(month from pt.received_date)
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
