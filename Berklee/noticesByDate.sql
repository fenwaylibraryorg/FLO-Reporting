--metadb:function noticesByDate

DROP FUNCTION IF EXISTS noticesByDate;

CREATE FUNCTION noticesByDate(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (date_sent date,
  notice_type text,
  notice_count integer)
AS $$
select cast(est.date as date) as "date sent", est."header" as "notice type", count(est.id)
from folio_email.email_statistics__t__ est
where cast(est.date as date) between '2025-12-01' and '2025-12-04'
group by cast(est.date as date), est."header"
order by cast(est.date as date), est."header"
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
