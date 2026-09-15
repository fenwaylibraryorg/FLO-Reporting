--metadb:function openPOL

DROP FUNCTION IF EXISTS openPOL;

CREATE FUNCTION openPOL(    
  start_ordered_date date DEFAULT '2000-01-01',
  end_ordered_date date DEFAULT '2050-01-01')
RETURNS TABLE
  (po_number text,
  vendor_name text,
  date_ordered timestamptz,
  po_status text,
  po_line_number text,
  bib_hrid text,
  index_title text,
  holdings_hrid text,
  receipt_status text,
  shelving_loc text,
  fund_distribution_code text,
  fiscal_year text
  )
AS $$
WITH ploc AS (
    SELECT
        p.id::uuid AS pol_id,
        jsonb_extract_path_text(locations.data, 'locationId')::uuid AS pol_location_id,
        jsonb_extract_path_text(locations.data, 'holdingId')::uuid AS pol_holding_id,
        jsonb_extract_path_text(locations.data, 'quantity')::int AS pol_loc_qty,
        jsonb_extract_path_text(locations.data, 'quantityElectronic')::int AS pol_loc_qty_elec,
        jsonb_extract_path_text(locations.data, 'quantityPhysical')::int AS pol_loc_qty_phys
    FROM
        folio_orders.po_line AS p
        CROSS JOIN LATERAL jsonb_array_elements(jsonb_extract_path(jsonb, 'locations')) AS locations (data)
),
  po_fund AS (
    SELECT
        id AS po_line_id,
        purchaseorderid,
        jsonb_extract_path_text(dist.data, 'code') AS fund_distribution_code,
        cast(jsonb_extract_path_text(dist.data, 'fundId') AS uuid) AS fund_distribution_id,
        jsonb_extract_path_text(dist.data, 'distributionType') AS fund_distribution_type,
        jsonb_extract_path_text(dist.data, 'value')::numeric(19,4) AS fund_distribution_value,
        jsonb_extract_path_text(po_line.jsonb, 'poLineNumber') AS poline_number,
        cast(jsonb_extract_path_text(po_line.jsonb, 'cost', 'poLineEstimatedPrice') AS numeric(19,4)) AS poline_estimated_price,
        jsonb_extract_path_text(po_line.jsonb, 'cost', 'currency') AS poline_currency,
        cast(jsonb_extract_path_text(po_line.jsonb, 'cost', 'listUnitPrice') AS numeric(19,4)) AS poline_listunitprice,
        cast(jsonb_extract_path_text(po_line.jsonb, 'cost', 'quantityPhysical') AS integer) AS poline_quantityphysical,
        cast(jsonb_extract_path_text(po_line.jsonb, 'cost', 'listUnitPriceElectronic') AS numeric(19,4)) AS poline_listunitpriceelectronic,
        cast(jsonb_extract_path_text(po_line.jsonb, 'cost', 'quantityElectronic') AS integer) AS poline_quantityelectronic,
        cast(jsonb_extract_path_text(po_line.jsonb, 'cost', 'additionalCost') AS numeric(19,4)) AS poline_additionalcost,
        jsonb_extract_path_text(po_line.jsonb, 'cost', 'discount') AS poline_discount,
        jsonb_extract_path_text(po_line.jsonb, 'cost', 'discountType') AS poline_discounttype,
        cast(jsonb_extract_path_text(po_line.jsonb, 'cost', 'fyroAdjustmentAmount') AS numeric(19,4)) AS po_line_fyroadjustmentamount,
        jsonb_extract_path_text(po_line.jsonb, 'titleOrPackage') AS poline_title_or_package
    FROM
        folio_orders.po_line AS po_line
        CROSS JOIN LATERAL jsonb_array_elements(jsonb_extract_path(jsonb, 'fundDistribution')) AS dist (data)
),
  finance AS (
    SELECT
        finance_storage_fund.id AS fund_id,
        jsonb_extract_path_text(finance_storage_fund.jsonb, 'code') AS fund_code,
        finance_storage_budget.id AS budget_id,
        jsonb_extract_path_text(finance_storage_budget.jsonb, 'name') AS budget_name,
        finance_storage_fiscal_year.id AS fiscal_year_id,
        jsonb_extract_path_text(finance_storage_fiscal_year.jsonb, 'code') AS fiscal_year
    FROM
        folio_finance.fiscal_year AS finance_storage_fiscal_year
        LEFT JOIN folio_finance.ledger AS finance_storage_ledger ON finance_storage_ledger.fiscalyearoneid = finance_storage_fiscal_year.id
        LEFT JOIN folio_finance.fund AS finance_storage_fund ON finance_storage_fund.ledgerid = finance_storage_ledger.id
        LEFT JOIN folio_finance.budget AS finance_storage_budget ON finance_storage_budget.fundid = finance_storage_fund.id
            AND finance_storage_budget.fiscalyearid = finance_storage_fiscal_year.id
)
select 
  pot.po_number, 
  org.name as vendor_name, 
  pot.date_ordered, 
  pot.workflow_status as po_status,
  plt.po_line_number,
  it.hrid as bib_hrid,
  it.index_title,
  hrt.hrid as holdings_hrid,
  plt.receipt_status,
  lt.name as shelving_loc,
  po_fund.fund_distribution_code,
  finance.fiscal_year
  from
folio_orders.purchase_order__t pot
left join folio_orders.po_line__t plt on (pot.id = plt.purchase_order_id::uuid) 
left join folio_organizations.organizations__t org on (org.id = pot.vendor::uuid) 
left join folio_inventory.instance__t it on (it.id = plt.instance_id::uuid) 
left join ploc on (ploc.pol_id = plt.id) 
left join folio_inventory.holdings_record__t hrt on (ploc.pol_holding_id::uuid = hrt.id) 
left join folio_inventory.location__t lt on (hrt.effective_location_id = lt.id) 
left join po_fund on (po_fund.po_line_id = plt.id) 
left join finance on (finance.fund_id = po_fund.fund_distribution_id) 
where plt.receipt_status <> 'Fully Received' and plt.receipt_status <> 'Cancelled' and pot.date_ordered between start_ordered_date and end_ordered_date
order by pot.po_number, split_part(plt.po_line_number, '-', 2)::int
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
