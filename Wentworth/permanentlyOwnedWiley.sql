--metadb:function permanentlyOwnedWiley

DROP FUNCTION IF EXISTS permanentlyOwnedWiley;

CREATE FUNCTION permanentlyOwnedWiley()
RETURNS TABLE
  (holdings_hrid text,
  note text,
  call_number text)
AS $$
SELECT holdings_ext.holdings_hrid, holdings_notes.note, holdings_ext.call_number
FROM folio_derived.holdings_notes
INNER JOIN folio_derived.holdings_ext
  on holdings_notes.holding_id = holdings_ext.holdings_id
WHERE holdings_notes.note LIKE 'Permanently owned' and holdings_ext.call_number LIKE 'Wiley'
  $$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
