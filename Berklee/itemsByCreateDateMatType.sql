--metadb:function itemsByCreateDateMatType

DROP FUNCTION IF EXISTS itemsByCreateDateMatType;

CREATE FUNCTION itemsByCreateDateMatType(    
  start_date date DEFAULT '2000-01-01',
  end_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (material_type_name text,
  item_count integer)
AS $$
select ie.material_type_name, count (distinct ie.item_id) as item_count
  from folio_derived.item_ext ie
where ie.created_date between start_date and end_date 
group by ie.material_type_name 
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
