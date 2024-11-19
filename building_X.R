library(DBI)
library(RPostgres)
library(dplyr)
library(dbplyr)

# Import Compustat
file_path <- file.path("data", "wrds_data", "compustat_all.rds")
if (file.exists(file_path)) {
  compustat_all <- readRDS(file_path)
} else {
  print("File not found. Please check the file path.")
}

# Import CRSP
file_path <- file.path("data", "wrds_data", "crsp_daily.rds")
if (file.exists(file_path)) {
  crsp_daily <- readRDS(file_path)
} else {
  print("File not found. Please check the file path.")
}

# Import ccmxpf_linktable
file_path <- file.path("data", "wrds_data", "ccmxpf_linktable.rds")
if (file.exists(file_path)) {
  ccmxpf_linktable <- readRDS(file_path)
} else {
  print("File not found. Please check the file path.")
}


#create a year column
crsp_daily$fyear <- as.Date(crsp_daily$date)
crsp_daily$fyear <- as.integer(format(crsp_daily$fyear, "%Y"))

#take only year from 2010 to 2024
crsp_daily <- crsp_daily %>%
  filter(fyear >= 2010 & fyear <= 2024)
compustat_all <- compustat_all %>%
  filter(fyear >= 2010 & fyear <= 2024)

#merge crsp and linktable and select only the columns we need to merge and compute financial ratios
merged_crsp_link <- crsp_daily %>%
  select(permno, prc, shrout, fyear, date) %>%
  left_join(ccmxpf_linktable, by = c("permno"), relationship = "many-to-many") %>% 
  filter(!is.na(gvkey) & 
           (date >= linkdt & date <= linkenddt))

#select only the columns we need to compute financial ratios
compustat_all <- compustat_all %>%
  select(
    gvkey, datadate, fyear,
    lct, invt, at, 
    ni, ceq, revt, 
    cogs, lt, , csho, 
    oancf, capx, 
    ebitda, seq, 
    dlc, dltt, 
    xint, pstkl, 
    txdb, pstkrv
  )

names(merged_crsp_link)

#for each couple of year and permno replace the variable by their mean value for this year
merged_crsp_link <- merged_crsp_link %>%
  group_by(fyear, permno) %>%
  summarise(
    gvkey=first(gvkey),
    prc=mean(prc, na.rm = TRUE),
    shrout=mean(shrout, na.rm = TRUE),
  )

#for each year and gvkey replace the variable by their mean value for this year
compustat_all <- compustat_all %>%
  group_by(fyear, gvkey) %>%
  summarise(
    lct=mean(lct, na.rm = TRUE),
    invt=mean(invt, na.rm = TRUE),
    at=mean(at, na.rm = TRUE),
    ni=mean(ni, na.rm = TRUE),
    ceq=mean(ceq, na.rm = TRUE),
    revt=mean(revt, na.rm = TRUE),
    cogs=mean(cogs, na.rm = TRUE),
    lt=mean(lt, na.rm = TRUE),
    csho=mean(csho, na.rm = TRUE),
    oancf=mean(oancf, na.rm = TRUE),
    capx=mean(capx, na.rm = TRUE),
    ebitda=mean(ebitda, na.rm = TRUE),
    seq=mean(seq, na.rm = TRUE),
    dlc=mean(dlc, na.rm = TRUE),
    dltt=mean(dltt, na.rm = TRUE),
    xint=mean(xint, na.rm = TRUE),
    pstkl=mean(pstkl, na.rm = TRUE),
    txdb=mean(txdb, na.rm = TRUE),
    pstkrv=mean(pstkrv, na.rm = TRUE)
  )

#merge compustat with crsp
merged_crsp_compustat <- merged_crsp_link  %>%
  left_join(compustat_all, by = c("gvkey", "fyear"))


print(merged_crsp_compustat, n=200)

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
    fyear, gvkey, 
    ROA, ROE, net_profit_margin, 
    asset_turnover, inventory_turnover, 
    debt_to_equity, debt_ratio, 
    PE_ratio, market_to_book, 
    operating_cash_flow_to_debt, free_cash_flow_to_sales, 
    book_value, 
    ebitda, ebitda_margin, roic, leverage, 
    interest_coverage
  )


# Save X in a rds file
saveRDS(X, file = "data/X.rds")
