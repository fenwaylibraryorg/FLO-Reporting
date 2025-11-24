--metadb:function circCountByiType

DROP FUNCTION IF EXISTS circCountByiType;

CREATE FUNCTION circCountByiType(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
    material_type text,
    circ_count integer
)
AS $$
select mtt."name" as material_type, count(distinct li.id) as circ_count from
folio_circulation.loan__t__ li
left join folio_inventory.item__t it on (it.id = li.item_id) 
left join folio_inventory.material_type__t mtt on (it.material_type_id = mtt.id)
where li.loan_date between start_date and end_date
group by mtt.name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
