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
select est.date::date as date_sent, est."header" as notice_type, count(est.id) as notice_count
from folio_email.email_statistics__t__ est
where est.date::date between start_date and end_date
group by est.date::date, est."header"
order by est.date::date, est."header"
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
