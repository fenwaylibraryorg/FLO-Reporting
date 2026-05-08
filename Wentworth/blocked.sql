--metadb:function blocked

DROP FUNCTION IF EXISTS blocked;
    
CREATE FUNCTION blocked()   
RETURNS TABLE
    (user_id uuid,
    user_last_name text,
    user_first_name text,
    barcode text,
    user_email text,
    group_name text,
    loan_count integer, 
    lost_loans integer,
    user_fines text,
    block_reason text)
AS $$
with user_loans as
  (select count(li.loan_id) as loan_count, ug.user_id 
  from
  folio_derived.loans_items li
  left join folio_derived.users_groups ug on (li.user_id = ug.user_id) 
  where loan_status = 'Open'
  group by ug.user_id),
lost_loans as
  (select count(li.loan_id) as loan_count, ug.user_id 
  from
  folio_derived.loans_items li
  left join folio_derived.users_groups ug on (li.user_id = ug.user_id) 
  where loan_status = 'Open' and li.item_status ilike '%lost%'
  group by ug.user_id)
select ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count as lost_loans, concat('$', sum(at2.remaining)) as user_fines, 'Max fine balance exceeded' as block_reason
from folio_derived.users_groups ug
inner join folio_feesfines.accounts__t at2 on (ug.user_id=at2.user_id)
left join user_loans ul on (ug.user_id = ul.user_id) 
left join lost_loans ll on (ug.user_id = ll.user_id) 
where at2.remaining > 0 and ug.group_name in ('Emeritus', 'Library Staff') 
group by ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count, block_reason
having sum(at2.remaining) >= 1000
UNION
select ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count as lost_loans, concat('$', sum(at2.remaining)) as user_fines, 'Max fine balance exceeded' as block_reason
from folio_derived.users_groups ug
inner join folio_feesfines.accounts__t at2 on (ug.user_id=at2.user_id)
left join user_loans ul on (ug.user_id = ul.user_id) 
left join lost_loans ll on (ug.user_id = ll.user_id) 
where at2.remaining > 0 and ug.group_name in ('Alumnus') 
group by ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count, block_reason
having sum(at2.remaining) >= 180
UNION
select ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count as lost_loans, concat('$', sum(at2.remaining)) as user_fines, 'Max fine balance exceeded' as block_reason
from folio_derived.users_groups ug
inner join folio_feesfines.accounts__t at2 on (ug.user_id=at2.user_id)
left join user_loans ul on (ug.user_id = ul.user_id) 
left join lost_loans ll on (ug.user_id = ll.user_id) 
where at2.remaining > 0 and ug.group_name = 'FLO User'
group by ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count, block_reason
having sum(at2.remaining) >= 300
UNION
select ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count as lost_loans, concat('$', sum(at2.remaining)) as user_fines, 'Max fine balance exceeded' as block_reason
from folio_derived.users_groups ug
inner join folio_feesfines.accounts__t at2 on (ug.user_id=at2.user_id)
left join user_loans ul on (ug.user_id = ul.user_id) 
left join lost_loans ll on (ug.user_id = ll.user_id) 
where at2.remaining > 0 and ug.group_name in ('Student', 'Graduate') 
group by ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count, block_reason
having sum(at2.remaining) >= 600
UNION
select ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count as lost_loans, concat('$', sum(at2.remaining)) as user_fines, 'Max checkouts exceeded' as block_reason from 
folio_derived.users_groups ug
left join folio_derived.loans_items li on (li.user_id = ug.user_id) 
inner join folio_feesfines.accounts__t at2 on (ug.user_id=at2.user_id)
left join user_loans ul on (ug.user_id = ul.user_id) 
left join lost_loans ll on (ug.user_id = ll.user_id) 
where (ug.group_name = 'Alumnus' or ug.group_name = 'FLO User') and ul.loan_count >= 15 
group by ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count, block_reason
UNION
select ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count as lost_loans, concat('$', sum(at2.remaining)) as user_fines, 'Max checkouts exceeded' as block_reason from 
folio_derived.users_groups ug
left join folio_derived.loans_items li on (li.user_id = ug.user_id) 
inner join folio_feesfines.accounts__t at2 on (ug.user_id=at2.user_id)
left join user_loans ul on (ug.user_id = ul.user_id) 
left join lost_loans ll on (ug.user_id = ll.user_id) 
where (ug.group_name = 'Student') and ul.loan_count >= 50
group by ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count, block_reason
UNION
select ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count as lost_loans, concat('$', sum(at2.remaining)) as user_fines, 'Max checkouts exceeded' as block_reason from 
folio_derived.users_groups ug
left join folio_derived.loans_items li on (li.user_id = ug.user_id) 
inner join folio_feesfines.accounts__t at2 on (ug.user_id=at2.user_id)
left join user_loans ul on (ug.user_id = ul.user_id) 
left join lost_loans ll on (ug.user_id = ll.user_id) 
where ug.group_name in ('Library Staff', 'Graduate')  and ul.loan_count >= 100
group by ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count, block_reason
UNION
select ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count as lost_loans, concat('$', sum(at2.remaining)) as user_fines, 'Max checkouts exceeded' as block_reason from 
folio_derived.users_groups ug
left join folio_derived.loans_items li on (li.user_id = ug.user_id) 
inner join folio_feesfines.accounts__t at2 on (ug.user_id=at2.user_id)
left join user_loans ul on (ug.user_id = ul.user_id) 
left join lost_loans ll on (ug.user_id = ll.user_id) 
where ug.group_name = 'Staff' and ul.loan_count >= 200
group by ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count, block_reason
UNION
select ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count as lost_loans, concat('$', sum(at2.remaining)) as user_fines, 'Max lost items exceeded' as block_reason from 
folio_derived.users_groups ug
left join folio_derived.loans_items li on (li.user_id = ug.user_id) 
inner join folio_feesfines.accounts__t at2 on (ug.user_id=at2.user_id)
left join user_loans ul on (ug.user_id = ul.user_id) 
left join lost_loans ll on (ug.user_id = ll.user_id) 
where ug.group_name in ('Alumnus', 'Emeritus', 'Graduate', 'Library Staff', 'Student') and ll.loan_count >=10
group by ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count, block_reason
UNION
select ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count as lost_loans, concat('$', sum(at2.remaining)) as user_fines, 'Max lost items exceeded' as block_reason from 
folio_derived.users_groups ug
left join folio_derived.loans_items li on (li.user_id = ug.user_id) 
inner join folio_feesfines.accounts__t at2 on (ug.user_id=at2.user_id)
left join user_loans ul on (ug.user_id = ul.user_id) 
left join lost_loans ll on (ug.user_id = ll.user_id) 
where ug.group_name = 'FLO User' and ll.loan_count >=5
group by ug.user_id, ug.user_last_name, ug.user_first_name, ug.barcode, ug.user_email, ug.group_name, ul.loan_count, ll.loan_count, block_reason
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
