--metadb:function ereserveBarcode

DROP FUNCTION IF EXISTS ereserveBarcode;

CREATE FUNCTION ereserveBarcode()
RETURNS TABLE
  (barcode text,
  title text,
  instance_hrid text
  )
AS $$
SELECT 
  ie.barcode,
  ie2.title,
  ie2.instance_hrid
FROM folio_derived.item_ext ie
  LEFT JOIN folio_derived.holdings_ext he on (ie.holdings_record_id = he.holdings_id)
  LEFT JOIN folio_derived.instance_ext ie2 on (he.instance_id = ie2.instance_id)
WHERE barcode LIKE 'ereserve%' ORDER BY barcode
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
