library(DBI)
library(RPostgres)
library(dplyr)
library(dbplyr)

# Import Compustat
file_path <- file.path("..", "data", "wrds_data", "compustat_all.rds")
if (file.exists(file_path)) {
  compustat_all <- readRDS(file_path)
} else {
  print("File not found. Please check the file path.")
}

# Import CRSP
file_path <- file.path("..", "data", "wrds_data", "crsp_daily.rds")
if (file.exists(file_path)) {
  crsp_daily <- readRDS(file_path)
} else {
  print("File not found. Please check the file path.")
}

#merge df and select only the columns we need to merge and compute financial ratios
merged_crsp_compustat <- crsp_daily %>%
  select(permno, date, prc, shrout) %>%
  left_join(ccmxpf_linktable, by = c("permno"), relationship = "many-to-many") %>% 
  filter(!is.na(gvkey) & 
           (date >= linkdt & date <= linkenddt))

#select only the columns we need to compute financial ratios
compustat_all <- compustat_all %>%
  select(
    gvkey, datadate,
    lct, invt, at, 
    ni, ceq, revt, 
    cogs, lt, , csho, 
    oancf, capx, 
    ebitda, seq, 
    dlc, dltt, 
    xint, pstkl, 
    txdb, pstkrv
  )

merged_crsp_compustat <- merged_crsp_compustat  %>%
  left_join(compustat_all, by = c("gvkey", "date"= "datadate"))

#drop na values
merged_crsp_compustat <- na.omit(merged_crsp_compustat)

#transform the date to only give the year without the month and day
merged_crsp_compustat$date <- as.Date(merged_crsp_compustat$date)
merged_crsp_compustat$date <- as.numeric(format(merged_crsp_compustat$date, "%Y"))

names(merged_crsp_compustat)
  
#Compute financial ratios
merged_crsp_compustat <- merged_crsp_compustat %>%
  mutate(
    # Profitability Ratios
    ROA = ni / at,                            # Return on Assets (ROA) = Net Income (ni) / Total Assets (at)
    ROE = ni / ceq,                           # Return on Equity (ROE) = Net Income (ni) / Common Equity (ceq)
    net_profit_margin = ni / revt,            # Net Profit Margin = Net Income (ni) / Total Revenue (revt)
    
    # Efficiency Ratios
    asset_turnover = revt / at,               # Asset Turnover = Total Revenue (revt) / Total Assets (at)
    inventory_turnover = cogs / invt,         # Inventory Turnover = Cost of Goods Sold (cogs) / Inventory (invt)
    
    # Leverage Ratios
    debt_to_equity = lt / ceq,                # Debt to Equity Ratio = Total Liabilities (lt) / Common Equity (ceq)
    debt_ratio = lt / at,                     # Debt Ratio = Total Liabilities (lt) / Total Assets (at)
    
    # Market Ratios
    PE_ratio = prc / (ni / csho),           # Price-to-Earnings (P/E) Ratio = Price per Share (prc) / (Net Income (ni) / Shares Outstanding (csho))
    market_to_book = (prc * csho) / ceq,    # Market to Book Ratio = (Price per Share (prc) * Shares Outstanding (csho)) / Common Equity (ceq)
    
    # Cash Flow Ratios
    operating_cash_flow_to_debt = oancf / lt, # Operating Cash Flow to Debt = Operating Cash Flow (oancf) / Total Liabilities (lt)
    free_cash_flow_to_sales = (oancf - capx) / revt, # Free Cash Flow to Sales = (Operating Cash Flow (oancf) - Capital Expenditures (capx)) / Total Revenue (revt)
    
    # Other Ratios
    book_value = at - pstkl - txdb - pstkrv - seq, # Book Value = Total Assets (at) - Preferred Stock Liquidating Value (pstkl) - Deferred Taxes (txdb) - Preferred Stock Redemption Value (pstkrv) - Shareholders' Equity (seq)
    ebitda = ebitda,                          # EBITDA = Earnings Before Interest, Taxes, Depreciation, and Amortization (ebitda)
    ebitda_margin = ebitda / revt,            # EBITDA Margin = EBITDA / Total Revenue (revt)
    roic = ebitda / (seq + dlc + dltt),       # Return on Invested Capital (ROIC) = EBITDA / (Shareholders' Equity (seq) + Short-Term Debt (dlc) + Long-Term Debt (dltt))
    leverage = (dlc + dltt) / (dlc + dltt + seq), # Leverage = (Short-Term Debt (dlc) + Long-Term Debt (dltt)) / (Short-Term Debt + Long-Term Debt + Shareholders' Equity (seq))
    interest_coverage = ebitda / xint         # Interest Coverage Ratio = EBITDA / Interest Expense (xint)
  )


# Now only keep the ratios we computed
X <- merged_crsp_compustat %>%
  select(
    date, gvkey, 
    ROA, ROE, net_profit_margin, 
    asset_turnover, inventory_turnover, 
    debt_to_equity, debt_ratio, 
    PE_ratio, market_to_book, 
    operating_cash_flow_to_debt, free_cash_flow_to_sales, 
    book_value, 
    ebitda, ebitda_margin, roic, leverage, 
    interest_coverage
  )


# Save X in a csv file
write.csv(X, file = "../data/our_data/X.csv", row.names = FALSE)