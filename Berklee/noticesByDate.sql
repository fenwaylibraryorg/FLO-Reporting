--metadb:function noticesByDate

DROP FUNCTION IF EXISTS noticesByDate;

CREATE FUNCTION noticesByDate(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (date_sent text,
  notice_type text,
  notice_count integer)
AS $$
select est.date::date::text as "date sent", est."header" as "notice type", count(est.id)
from folio_email.email_statistics__t__ est
where est.date::date between '2025-12-01' and '2025-12-04'
group by est.date::date, est."header"
order by est.date::date, est."header"
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
