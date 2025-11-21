--metadb:function expiredPatronNotes

DROP FUNCTION IF EXISTS expiredPatronNotes;

CREATE FUNCTION expiredPatronNotes()
RETURNS TABLE
  (id text,
  username text,
  barcode text, 
  external_system_id text,
  lastname text,
  firstname text,
  patron_group text,
  expiration_date timestamptz,
  note_title text,
  patron_note text)
AS $$
select
	distinct ut.id,
	ut.username,
	ut.barcode,
	ut.external_system_id,
	u.jsonb->'personal'->>'lastName' as lastName,
	u.jsonb->'personal'->>'firstName' as firstName,
	gt."group" as patron_group,
	date(ut.expiration_date) as expiration_date,
	un.title as note_title,
	un.content as patron_note
from
	folio_users.users__t ut
inner join folio_users.groups__t gt on
	ut.patron_group = gt.id
inner join folio_users.users u on
	ut.id = u.id
left join
(
	select
		distinct n.title,
		n.content,
		l.object_id as user_id
	from
		folio_notes.note_link nl
	inner join folio_notes.link l on
		nl.link_id = l.id
	inner join folio_notes.note n on
		nl.note_id = n.id
	where
		l.object_type = 'user') as un on
	ut.id = un.user_id
left join folio_circulation.loan__t lt on
	ut.id = lt.user_id
where
	/*	gt.group in ('Alumnus', 'Faculty', 'Student', 'Graduate', 'Staff')*/
	gt.group in ('Faculty', 'Student', 'Graduate', 'Staff')
	and date(ut.expiration_date) < date(date_trunc('month',now()-interval '1 month'))
	and ut.id not in (
	select
		distinct at2.user_id
	from
		folio_feesfines.accounts__t at2
	where
		at2.remaining>0)
	and lt.id is null
	and un.content is not null
 $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
