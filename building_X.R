library(DBI)
library(RPostgres)
library(dplyr)
library(dbplyr)

setwd("/Users/theodruilhe/Documents/M2_D3S/scoring_project")

# Import Compustat
file_path <- file.path("data", "wrds_data", "compustat_all.rds")
if (file.exists(file_path)) {
  compustat_all <- readRDS(file_path)
} else {
  stop("Compustat file not found. Please check the file path.")
}

# Import CRSP
file_path <- file.path("data", "wrds_data", "crsp_daily.rds")
if (file.exists(file_path)) {
  crsp_daily <- readRDS(file_path)
} else {
  stop("CRSP file not found. Please check the file path.")
}

# Import ccmxpf_linktable
file_path <- file.path("data", "wrds_data", "ccmxpf_linktable.rds")
if (file.exists(file_path)) {
  ccmxpf_linktable <- readRDS(file_path)
} else {
  stop("Linktable file not found. Please check the file path.")
}

# Create a year column and filter crsp_daily
crsp_daily <- crsp_daily %>%
  mutate(fyear = as.integer(format(as.Date(date), "%Y"))) %>%
  filter(fyear >= 2010 & fyear <= 2024)

# Filter compustat_all for the same period
compustat_all <- compustat_all %>%
  filter(fyear >= 2010 & fyear <= 2024)

# Deduplicate ccmxpf_linktable based on permno and date ranges
ccmxpf_linktable <- ccmxpf_linktable %>%
  arrange(permno, linkdt, linkenddt) %>% # Ensure ordering by permno and date
  group_by(permno) %>%
  filter(row_number() == 1) %>% # Keep only the first row for each permno
  ungroup()

# Merge crsp_daily with the deduplicated linktable
merged_crsp_link <- crsp_daily %>%
  select(permno, prc, shrout, fyear, date) %>%
  left_join(ccmxpf_linktable, by = "permno") %>%
  filter(!is.na(gvkey) & (date >= linkdt & date <= linkenddt)) %>% # Filter valid date ranges
  group_by(fyear, permno) %>%
  summarise(
    gvkey = first(gvkey), # Use the first gvkey (no duplicates due to deduplication)
    prc = mean(prc, na.rm = TRUE),
    shrout = mean(shrout, na.rm = TRUE),
    .groups = "drop"
  )
# Aggregate financial data from compustat_all
compustat_all <- compustat_all %>%
  group_by(fyear, gvkey) %>%
  summarise(
    lct = mean(lct, na.rm = TRUE),
    invt = mean(invt, na.rm = TRUE),
    at = mean(at, na.rm = TRUE),
    ni = mean(ni, na.rm = TRUE),
    ceq = mean(ceq, na.rm = TRUE),
    revt = mean(revt, na.rm = TRUE),
    cogs = mean(cogs, na.rm = TRUE),
    lt = mean(lt, na.rm = TRUE),
    csho = mean(csho, na.rm = TRUE),
    oancf = mean(oancf, na.rm = TRUE),
    capx = mean(capx, na.rm = TRUE),
    ebitda = mean(ebitda, na.rm = TRUE),
    seq = mean(seq, na.rm = TRUE),
    dlc = mean(dlc, na.rm = TRUE),
    dltt = mean(dltt, na.rm = TRUE),
    xint = mean(xint, na.rm = TRUE),
    pstkl = mean(pstkl, na.rm = TRUE),
    txdb = mean(txdb, na.rm = TRUE),
    pstkrv = mean(pstkrv, na.rm = TRUE),
    datadate = first(datadate),
    .groups = "drop"
  )

# Merge compustat_all with merged_crsp_link
merged_crsp_compustat <- merged_crsp_link %>%
  left_join(compustat_all, by = c("gvkey", "fyear"))

# Calculate financial ratios
merged_crsp_compustat <- merged_crsp_compustat %>%
  mutate(
    ROA = ifelse(at == 0, NA, ni / at),
    ROE = ifelse(ceq == 0, NA, ni / ceq),
    net_profit_margin = ifelse(revt == 0, NA, ni / revt),
    asset_turnover = ifelse(at == 0, NA, revt / at),
    inventory_turnover = ifelse(invt == 0, NA, cogs / invt),
    debt_to_equity = ifelse(ceq == 0, NA, lt / ceq),
    debt_ratio = ifelse(at == 0, NA, lt / at),
    PE_ratio = ifelse(csho == 0 | ni == 0, NA, prc / (ni / csho)),
    market_to_book = ifelse(ceq == 0, NA, (prc * csho) / ceq),
    operating_cash_flow_to_debt = ifelse(lt == 0, NA, oancf / lt),
    free_cash_flow_to_sales = ifelse(revt == 0, NA, (oancf - capx) / revt),
    book_value = at - pstkl - txdb - pstkrv - seq,
    ebitda_margin = ifelse(revt == 0, NA, ebitda / revt),
    roic = ifelse((seq + dlc + dltt) == 0, NA, ebitda / (seq + dlc + dltt)),
    leverage = ifelse((dlc + dltt + seq) == 0, NA, (dlc + dltt) / (dlc + dltt + seq)),
    interest_coverage = ifelse(xint == 0, NA, ebitda / xint)
  )

# Final dataset
X <- merged_crsp_compustat %>%
  select(
    fyear, gvkey,
    ROA, ROE, net_profit_margin,
    asset_turnover, inventory_turnover,
    debt_to_equity, debt_ratio,
    PE_ratio, market_to_book,
    operating_cash_flow_to_debt, free_cash_flow_to_sales,
    book_value, ebitda, ebitda_margin, roic, leverage,
    interest_coverage
  )

# Save the dataset
saveRDS(X, file = "data/our_data/X.rds")

