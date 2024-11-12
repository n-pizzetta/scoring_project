library(DBI)
library(RPostgres)
library(dplyr)
library(dbplyr)

mapping <- ccmxpf_linktable %>% left_join(compustat_all, by = c("gvkey"))


merged_crsp_compustat_sub <- crsp_daily_light %>%
  select(cusip, permno, date, prc, vol, shrout, bid, ask) %>%
  left_join(mapping, by = c("permno"), relationship = "many-to-many") %>% 
  filter(!is.na(gvkey) & 
           (date >= linkdt & date <= linkenddt))
