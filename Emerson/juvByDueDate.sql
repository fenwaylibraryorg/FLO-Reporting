--metadb:function juvByDueDate

DROP FUNCTION IF EXISTS juvByDueDate;

CREATE FUNCTION juvByDueDate()
RETURNS TABLE
  (lc_area text,
  loan_count integer,
  due_date text)
AS $$
SELECT rtrim(substring(hrt.call_number from '.*(?=\.)')) AS Lc_area, COUNT(distinct lt2.id) as loan_count, lt2.due_date::date::text
FROM folio_circulation.loan__t lt2 /*uses current loans table*/
LEFT JOIN folio_inventory.item__t it ON (it.id = lt2.item_id)
  LEFT JOIN folio_inventory.holdings_record__t hrt ON (it.holdings_record_id = hrt.id)
  LEFT JOIN folio_inventory.call_number_type__t cntt ON (hrt.call_number_type_id = cntt.id)
  LEFT JOIN folio_inventory.material_type__t mtt ON (mtt.id = it.material_type_id)
WHERE (mtt.name LIKE 'Juvenile Books')
  AND (cntt.name LIKE 'Library of Congress%' OR cntt.name LIKE 'LC%')
GROUP BY Lc_area, lt2.due_date
ORDER BY Lc_area, lt2.due_date
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
