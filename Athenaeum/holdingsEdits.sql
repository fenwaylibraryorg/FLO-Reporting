--metadb:function holdingsEdits

DROP FUNCTION IF EXISTS holdingsEdits;

CREATE FUNCTION holdingsEdits(
  update_user text DEFAULT '%',
  start_update_date date DEFAULT '2000-01-01',
  end_update_date date DEFAULT '2050-01-01')
RETURNS TABLE(
  update_date_holdings text,
  update_staff_holdings text,
  instance_hrid text,
  title text,
  holdings_hrid text,
  call_number_prefix text,
  call_number text,
  discovery_suppress boolean,
  perm_holdings_location text,
  temp_holdings_location text,
  statistical_code text,
  create_date_holdings text,
  create_staff_holdings text 
  )
AS $$
WITH stcodes AS (
    SELECT
        h.instanceid AS instance_id,
        i.hrid AS instance_hrid,
        h.id AS holdings_id,
        jsonb_extract_path_text(h.jsonb, 'hrid') AS holdings_hrid,
        (sc.jsonb #>> '{}')::uuid AS statistical_code_id,
        sc.ordinality AS statistical_code_ordinality
    FROM
        folio_inventory.holdings_record AS h
        LEFT JOIN folio_inventory.instance__t AS i ON h.instanceid = i.id
        CROSS JOIN LATERAL jsonb_array_elements(jsonb_extract_path(h.jsonb, 'statisticalCodeIds')) WITH ORDINALITY AS sc (jsonb)
)
select 
  jsonb_extract_path_text(hr.jsonb, 'metadata', 'updatedDate')::date::text as update_date_holdings, 
  uuh.username as update_staff_holdings,
  it.hrid as instance_hrid,
  it.title,
  hrt.hrid as holdings_hrid,
  hrt.call_number_prefix,
  hrt.call_number,
  hrt.discovery_suppress,
  ltp.name as perm_holdings_location, 
  ltt.name as temp_holdings_location, 
  sct.code AS statistical_code,
  sct.name AS statistical_code_name,
  jsonb_extract_path_text(hr.jsonb, 'metadata', 'createdDate')::date::text as create_date_holdings, 
  cuh.username as create_staff_holdings
  from
folio_inventory.instance__t it
left join folio_inventory.holdings_record__t hrt on (hrt.instance_id = it.id) 
left join folio_inventory.holdings_record hr on (hr.id = hrt.id) 
left join folio_inventory.location__t ltp on (hrt.permanent_location_id = ltp.id) 
left join folio_inventory.location__t ltt on (hrt.temporary_location_id = ltt.id) 
left join stcodes stc on (stc.holdings_id = hrt.id) 
LEFT JOIN folio_inventory.statistical_code__t AS sct ON stc.statistical_code_id = sct.id
LEFT JOIN folio_inventory.statistical_code_type__t AS sctt ON sct.statistical_code_type_id::uuid = sctt.id::uuid
left join folio_derived.users_groups cuh on (jsonb_extract_path_text(hr.jsonb, 'metadata', 'createdByUserId')::uuid = cuh.user_id) 
left join folio_derived.users_groups uuh on (jsonb_extract_path_text(hr.jsonb, 'metadata', 'updatedByUserId')::uuid = uuh.user_id)
where ((jsonb_extract_path_text(hr.jsonb, 'metadata', 'updatedDate')::date between start_update_date and end_update_date) or
(jsonb_extract_path_text(hr.jsonb, 'metadata', 'createdDate')::date between start_update_date and end_update_date)) and (uuh.username like update_user)
order by jsonb_extract_path_text(hr.jsonb, 'metadata', 'updatedDate')::date, uuh.username, it.hrid, hrt.hrid
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
